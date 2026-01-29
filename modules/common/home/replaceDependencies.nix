# https://github.com/Cu3PO42/gleaming-glacier/blob/6a6786903b2d120b64d17f67dbf77d8dd4e15152/modules/home-manager/replace-dependencies.nix

# This module provides the equivalent of system.replaceDependencies, but
# for home-manager.
{
  pkgs,
  lib,
  config,
  copper,
  ...
}:
with lib;
let
  cfg = config.system;

  # This is copied from upstream home-manager/modules/home-environment.nix.
  # This should ideally be upstreamed.
  path = pkgs.buildEnv {
    name = "home-manager-path";

    paths = config.home.packages;
    inherit (config.home) extraOutputsToInstall;

    postBuild = config.home.extraProfileCommands;

    meta = {
      description = "Environment of packages installed through home-manager";
    };
  };

  patchedPath = pkgs.replaceDependencies {
    drv = path;
    replacements = cfg.replaceDependencies.replacements;
  };
in
{
  options = {
    system.replaceDependencies.replacements = mkOption {
      type =
        with types;
        listOf (submodule {
          options = {
            oldDependency = mkOption {
              type = package;
              description = "The original package to override.";
            };

            newDependency = mkOption {
              type = package;
              description = "The replacement package.";
            };
          };
        });
      default = [ ];
      example = literalExpression ''
        [
          {
            oldDependency = pkgs.libadwaita;
            newDependency = copper.packages.libadwaita-without-adwaita;
          }
        ]
      '';
      apply = map (
        { oldDependency, newDependency, ... }:
        {
          inherit oldDependency newDependency;
        }
      );
      description = ''
        List of packages to override without doing a full rebuild. The original
        derivation and replacement derivation must have the same name length,
        and ideally should have close-to-identical directory layout.
      '';
    };
  };

  config.home.path = mkIf (cfg.replaceDependencies.replacements != [ ]) (mkForce patchedPath);
}
