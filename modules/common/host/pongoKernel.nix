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
      (final: prev: {
        linuxPackages_pongo =
          (
            if cfg.crossCompile != null then
              inputs.nixpkgs2.legacyPackages.${cfg.crossCompile.host}.pkgsCross.${cfg.crossCompile.target}
            else
              inputs.nixpkgs2.legacyPackages.${system}
          ).linuxPackages_testing.extend
            (
              final': prev':
              let
                pkgs' = inputs.nixpkgs2.legacyPackages.${system};
              in
              {
                kernel = prev'.kernel.override {
                  buildPackages = pkgs'.buildPackages // {
                    stdenv = pkgs'.gcc15Stdenv;
                  };
                  stdenv = pkgs'.gcc15Stdenv;

                  ignoreConfigErrors = true;

                  argsOverride =
                    let
                      version = "6.18-git";
                    in
                    {
                      inherit version;
                      modDirVersion = "6.18.0-rc7";
                      src = final.fetchFromGitHub {
                        owner = "pongo1231";
                        repo = "linux";
                        rev = "6ec5ff8d05008533cbe7f9afd61d9244393893ec";
                        hash = "sha256-l6yMyO/BkWbay0+iWkxNU6YKlZUHUhSFQ6E6ZiHgbXw=";
                      };
                    };
                };

                xpadneo = prev'.xpadneo.overrideAttrs (
                  final'': prev'': {
                    src = pkgs.fetchFromGitHub {
                      owner = "atar-axis";
                      repo = "xpadneo";
                      rev = "a16acb03e7be191d47ebfbc8ca1d5223422dac3e";
                      hash = "sha256-4eOP6qAkD7jGOqaZPOB5/pdoqixl2Jy2iSVvK2caE80=";
                    };

                    patches = (prev''.patches or [ ]) ++ [ (patch /xpadneo/6.17/ida_alloc_and_free.patch) ];
                  }
                );
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
            PREEMPT_DYNAMIC y
            ZRAM_MEMORY_TRACKING y
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

      kernelParams = [ "vmscape=on" ];
    };
  };
}
