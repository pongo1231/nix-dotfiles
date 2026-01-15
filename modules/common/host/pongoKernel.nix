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
          let
            pkgs' =
              if cfg.crossCompile != null then
                inputs.nixpkgs2.legacyPackages.${cfg.crossCompile.host}.pkgsCross.${cfg.crossCompile.target}
              else
                inputs.nixpkgs2.legacyPackages.${system};
          in
          pkgs'.linuxPackages_testing.extend (
            final': prev': {
              kernel = prev'.kernel.override {
                buildPackages = pkgs'.buildPackages // {
                  stdenv = pkgs'.pkgsBuildBuild.gcc15Stdenv;
                };
                stdenv = pkgs'.gcc15Stdenv;
                pkgsBuildBuild = pkgs'.pkgsBuildBuild;

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
                      rev = "c7e1b2d831ea8f2b70be23d8f46af4b89fec955d";
                      hash = "sha256-DhR8O4U5naoHduIKpuhIkJ3MhOrEc4bc+FXyKNJQCFo=";
                    };
                  };
              };

              /*
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
              */
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
            PREEMPT y
            ZRAM_MEMORY_TRACKING y
            RSEQ_SLICE_EXTENSION y
            DRM_NOVA n
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
