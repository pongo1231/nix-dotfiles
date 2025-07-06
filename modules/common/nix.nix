{
  system,
  inputs,
  configInfo,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.pongo;
in
{
  options.pongo.useLixOverlay = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config =
    {
      nix =
        {
          package = lib.mkDefault pkgs.lixPackageSets.latest.lix;

          nixPath =
            if configInfo.type != "host" then
              [ "${config.xdg.configHome}/nix/inputs" ]
            else
              [ "/etc/nix/inputs" ];

          registry = lib.mapAttrs' (name: flake: {
            inherit name;
            value.flake = flake;
          }) inputs;

          extraOptions = ''
            experimental-features = nix-command flakes auto-allocate-uids cgroups
            keep-derivations = false
            auto-allocate-uids = true
            use-cgroups = true
          '';

          settings = {
            auto-optimise-store = true;
            trusted-users = [
              "root"
              "@wheel"
            ];
            substituters = [
              "https://cache.nixos.org"
              "https://nix-community.cachix.org"
              "https://pongo1231.cachix.org"
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "pongo1231.cachix.org-1:3B6q/T1NL/YPokIFY4lthjoI6vCMKiuYjTGY3gJtZPg="
            ];
          };
        }
        // lib.optionalAttrs (configInfo.type == "host") {
          daemonCPUSchedPolicy = "idle";
          daemonIOSchedClass = "idle";
        };

      nixpkgs =
        lib.optionalAttrs cfg.useLixOverlay {
          overlays = [ (final: prev: inputs.lix.overlays.default final prev) ];
        }
        // lib.optionalAttrs (configInfo.type == "host" || !configInfo.isNixosModule) {
          config = {
            allowUnfree = true;
            nvidia.acceptLicense = true;
          };
        }
        // lib.optionalAttrs (configInfo.type == "host") {
          hostPlatform.system = system;
        };
    }
    // lib.optionalAttrs (configInfo.type == "host") {
      fileSystems."/nix/var/nix/builds" = {
        fsType = "tmpfs";
        options = [
          "noatime"
          "mode=0755"
          "size=200%"
          "huge=within_size"
        ];
      };
    };
}
