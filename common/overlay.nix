{
  inputs,
  configInfo,
  patch,
  pkg,
  config,
  pkgs,
  lib,
  nixosConfig ? null,
  ...
}:
let
  cfg = config.pongo.overlay;
in
{
  options.pongo.overlay.enableUutils = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkMerge [
    {
      system.replaceDependencies.replacements =
        lib.optionals
          (
            configInfo.type == "host"
            || !configInfo.isNixosModule
            || (configInfo.type == "home" && !nixosConfig.pongo.overlay.enableUutils)
          )
          (
            [
              {
                oldDependency = pkgs.libdrm;
                newDependency = pkgs.libdrm.overrideAttrs {
                  version = "2.4.133";
                  src = pkgs.fetchurl {
                    url = "https://dri.freedesktop.org/libdrm/libdrm-2.4.133.tar.xz";
                    hash = "sha256-/Gj50LoupjyUMqKZ4U/qCfrXqKZugDn814AspZ93tPU=";
                  };
                };
              }
            ]
            ++ lib.optionals cfg.enableUutils [
              {
                oldDependency = pkgs.coreutils-full;
                newDependency = pkgs.symlinkJoin {
                  name =
                    "coreuutils-full"
                    + builtins.concatStringsSep "" (
                      builtins.genList (_: "_") (builtins.stringLength pkgs.coreutils-full.version)
                    );
                  paths = [ pkgs.uutils-coreutils-noprefix ];
                };
              }
              {
                oldDependency = pkgs.coreutils;
                newDependency = pkgs.symlinkJoin {
                  name =
                    "coreuutils"
                    + builtins.concatStringsSep "" (
                      builtins.genList (_: "_") (builtins.stringLength pkgs.coreutils.version)
                    );
                  paths = [ pkgs.uutils-coreutils-noprefix ];
                };
              }
              {
                oldDependency = pkgs.findutils;
                newDependency = pkgs.symlinkJoin {
                  name =
                    "finduutils"
                    + builtins.concatStringsSep "" (
                      builtins.genList (_: "_") (builtins.stringLength pkgs.findutils.version)
                    );
                  paths = [ pkgs.uutils-findutils ];
                };
              }
              {
                oldDependency = pkgs.diffutils;
                newDependency = pkgs.symlinkJoin {
                  name =
                    "diffuutils"
                    + builtins.concatStringsSep "" (
                      builtins.genList (_: "_") (builtins.stringLength pkgs.diffutils.version)
                    );
                  paths = [ pkgs.uutils-diffutils ];
                };
              }
            ]
          );
    }
    # https://github.com/NixOS/nixpkgs/blob/a80ba52593f87d41a21d84c4e37f077c3604ca6a/pkgs/build-support/replace-dependencies.nix#L7
    #pkgs.replaceDependencies = { };

    (lib.optionalAttrs (configInfo.type == "host" || !configInfo.isNixosModule) {
      nixpkgs.overlays = [
        (import ../overlays { inherit inputs patch pkg; })
      ];
    })
  ];
}
