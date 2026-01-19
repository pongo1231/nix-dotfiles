{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.pongo.pongoKernel;
in
{
  options.pongo.pongoKernel = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    crossCompile = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        linuxPackages_pongo =
          let
            pkgs' =
              if cfg.crossCompile != null then
                inputs.nixpkgs2.legacyPackages.${cfg.crossCompile.host}.pkgsCross.${cfg.crossCompile.target}
              else
                inputs.nixpkgs2.legacyPackages.${pkgs.stdenv.hostPlatform.system};
          in
          pkgs'.linuxPackages_testing.extend (
            final': prev': {
              kernel = prev'.kernel.override {
                buildPackages = pkgs'.buildPackages // {
                  stdenv = pkgs'.pkgsBuildBuild.gcc15Stdenv;
                };
                stdenv = pkgs'.gcc15Stdenv;
                inherit (pkgs') pkgsBuildBuild;

                ignoreConfigErrors = true;

                argsOverride =
                  let
                    version = "6.19-git";
                  in
                  {
                    inherit version;
                    modDirVersion = "6.19.0-rc5";
                    src = final.fetchFromGitHub {
                      owner = "pongo1231";
                      repo = "linux";
                      rev = "4c8717e8dc32a3af03f19e30fcc98945eba7a3de";
                      hash = "sha256-mkgT36dmXAjJ2L0P4cg6EKCs1MPo4igdCbAZ2V/Acjc=";
                    };
                  };
              };
            }
          );
      })
    ];

    boot = {
      kernelPackages = pkgs.linuxPackages_pongo;

      kernelPatches = [
        {
          name = "base";
          patch = null;
          extraConfig = ''
            BTRFS_EXPERIMENTAL y
            PREEMPT_DYNAMIC n
            PREEMPT_VOLUNTARY n
            PREEMPT y
            ZRAM_MEMORY_TRACKING y
            RSEQ_SLICE_EXTENSION y
            DRM_NOVA n
          ''
          + lib.optionalString (pkgs.stdenv.hostPlatform.system == "x86_64-linux") ''
            X86_64_VERSION 3
            AMD_PRIVATE_COLOR y
            LEDS_STEAMDECK m
            EXTCON_STEAMDECK m
            MFD_STEAMDECK m
            SENSORS_STEAMDECK m
          '';
        }
      ];

      kernelParams = [ "vmscape=on" ];
    };
  };
}
