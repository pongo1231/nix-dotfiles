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

    enableHardening = lib.mkOption {
      type = lib.types.bool;
      default = false;
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
                pkgs' =
                  if cfg.crossCompile != null then
                    inputs.nixpkgs2.legacyPackages.${cfg.crossCompile.host}
                  else
                    inputs.nixpkgs2.legacyPackages.${system};
              in
              {
                kernel =
                  let
                    stdenv = pkgs'.stdenvAdapters.overrideInStdenv pkgs'.llvmPackages_21.stdenv [
                      pkgs'.llvmPackages_21.llvm
                      pkgs'.llvmPackages_21.lld
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
                        modDirVersion = "6.17.0-rc5";
                        src = final.fetchFromGitHub {
                          owner = "pongo1231";
                          repo = "linux";
                          rev = "d452e31a001c52bd8916e07d6d2bf20393c133c6";
                          hash = "sha256-bEVTq0IkH/pqqkpVXU36ormEXXxHadyi5M3uaACKH9o=";
                        };
                      };

                    extraMakeFlags =
                      let
                        llvmPkgs = pkgs'.llvmPackages_21;
                      in
                      [
                        "LLVM=1"
                        "CC=${llvmPkgs.clang-unwrapped}/bin/clang"
                        "AR=${llvmPkgs.llvm}/bin/llvm-ar"
                        "NM=${llvmPkgs.llvm}/bin/llvm-nm"
                        "LD=${llvmPkgs.lld}/bin/ld.lld"
                      ];

                    structuredExtraConfig =
                      with lib.kernel;
                      {
                        LTO_CLANG_THIN_DIST = lib.mkForce yes;
                      }
                      // lib.optionalAttrs cfg.enableHardening {
                        CFI_CLANG = lib.mkForce yes;
                        UBSAN = lib.mkForce yes;
                        UBSAN_TRAP = lib.mkForce yes;
                        UBSAN_LOCAL_BOUNDS = lib.mkForce yes;
                        UBSAN_SHIFT = lib.mkForce no;
                        UBSAN_BOOL = lib.mkForce no;
                        UBSAN_ENUM = lib.mkForce no;
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

                    makeFlags = prev''.makeFlags ++ final'.kernel.extraMakeFlags;

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

      kernel.randstructSeed = "damnthissucks";
    };

    services.udev.extraRules = ''
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]|sd[a-z]*|mmcblk[0-9]*", ATTR{queue/scheduler}="adios"
    '';
  };
}
