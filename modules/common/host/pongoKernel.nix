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
      (
        final: prev:
        let
          pkgs' =
            if cfg.crossCompile != null then
              inputs.nixpkgs2.legacyPackages.${cfg.crossCompile.host}.pkgsCross.${cfg.crossCompile.target}
            else
              inputs.nixpkgs2.legacyPackages.${system};
        in
        {
          linuxPackages_pongo = pkgs'.linuxPackages_testing.extend (final': prev': {
              kernel =
                let
                  stdenv = pkgs'.stdenvAdapters.overrideInStdenv pkgs'.llvmPackages_latest.stdenv [
                    pkgs'.llvmPackages_latest.llvm
                    pkgs'.llvmPackages_latest.lld
                  ];
                in
                prev'.kernel.override {
                  buildPackages = pkgs'.buildPackages // {
                    inherit stdenv;
                  };

                  inherit stdenv;

                  ignoreConfigErrors = true;

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
                        rev = "3e5bfdc17896bf8728445464da017b6ce9f1126a";
                        hash = "sha256-jZieJJYiI+m+xahjhNJiRnD0Kw8I8LJLrsVVd0M7Huw=";
                      };
                    };

                  extraMakeFlags =
                    let
                      llvmPkgs = pkgs'.llvmPackages_latest;
                    in
                    [
                      "LLVM=1"
                      "CC=${llvmPkgs.clang-unwrapped}/bin/clang"
                      "AR=${llvmPkgs.llvm}/bin/llvm-ar"
                      "NM=${llvmPkgs.llvm}/bin/llvm-nm"
                      "LD=${llvmPkgs.lld}/bin/ld.lld"
                    ];

                  structuredExtraConfig = with lib.kernel; {
                    CC_IS_CLANG = lib.mkForce yes;
                    LTO = lib.mkForce yes;
                    LTO_CLANG = lib.mkForce yes;
                    LTO_CLANG_THIN = lib.mkForce yes;
                  };

                  defconfig = "defconfig LLVM=1";
                };

              xpadneo = prev'.xpadneo.overrideAttrs (final'': prev'': {
                src = pkgs.fetchFromGitHub {
                  owner = "atar-axis";
                  repo = "xpadneo";
                  rev = "a16acb03e7be191d47ebfbc8ca1d5223422dac3e";
                  hash = "sha256-4eOP6qAkD7jGOqaZPOB5/pdoqixl2Jy2iSVvK2caE80=";
                };

                makeFlags = prev''.makeFlags ++ final'.kernel.extraMakeFlags;

                patches = (prev''.patches or [ ]) ++ [ (patch /xpadneo/6.17/ida_alloc_and_free.patch) ];
              });
            }
          );
        }
      )
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
