{
  inputs,
  system,
  patch,
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
      (final: _: {
        linuxPackages_pongo =
          (
            if cfg.crossCompile != null then
              inputs.nixpkgs2.legacyPackages.${cfg.crossCompile.host}.pkgsCross.${cfg.crossCompile.target}.linuxPackages_testing
            else
              inputs.nixpkgs2.legacyPackages.${system}.linuxPackages_testing
          ).extend
            (
              let
                pkgs' = inputs.nixpkgs2.legacyPackages.${system};
              in
              _: prev': {
                kernel = (
                  prev'.kernel.override {
                      buildPackages = pkgs.buildPackages // {
                      	stdenv = pkgs.gcc15Stdenv;
                      };

                      #ignoreConfigErrors = true;

                      argsOverride =
                        let
                          version = "6.17.0-git";
                        in
                        {
                          inherit version;
                          modDirVersion = "6.17.0-rc2";
                          src = final.fetchFromGitHub {
                            owner = "pongo1231";
                            repo = "linux";
                            rev = "4bbe85b01f94fccf78e897068ae636fb29871d92";
                            hash = "sha256-GxMQ81oDF2XSorqcStkjgkZ2HCR0Lr3OsBD4vhHh07Q=";
                          };
                        };
                    }
                );

                xpadneo = prev'.xpadneo.overrideAttrs {
                  src = final.fetchFromGitHub {
                    owner = "atar-axis";
                    repo = "xpadneo";
                    rev = "a16acb03e7be191d47ebfbc8ca1d5223422dac3e";
                    hash = "sha256-4eOP6qAkD7jGOqaZPOB5/pdoqixl2Jy2iSVvK2caE80=";
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
            CC_OPTIMIZE_FOR_PERFORMANCE_O3 y
            BTRFS_EXPERIMENTAL y
            PREEMPT_DYNAMIC y
          ''
          + lib.optionalString (system == "x86_64-linux") ''
            X86_64_VERSION 3
            AMD_PRIVATE_COLOR y
            LEDS_STEAMDECK m
            EXTCON_STEAMDECK m
            MFD_STEAMDECK m
            SENSORS_STEAMDECK m
          '';
        }
      ];

      kernelModules = [ "adios" ];
    };

    services.udev.extraRules = ''
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]|sd[a-z]*|mmcblk[0-9]*", ATTR{queue/scheduler}="adios"
    '';
  };
}
