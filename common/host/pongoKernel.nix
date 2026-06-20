{
  inputs,
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
      default = true;
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
                inputs.nixpkgs4.legacyPackages.${cfg.crossCompile.host}.pkgsCross.${cfg.crossCompile.target}
              else
                inputs.nixpkgs4.legacyPackages.${pkgs.stdenv.hostPlatform.system};
          in
          pkgs'.linuxPackages_testing.extend (
            final': prev': {
              kernel =
                let
                  llvm =
                    if cfg.crossCompile != null then
                      inputs.nixpkgs4.legacyPackages.${cfg.crossCompile.host}.llvmPackages_latest
                    else
                      inputs.nixpkgs4.legacyPackages.${pkgs.stdenv.hostPlatform.system}.llvmPackages_latest;
                  llvmTarget = pkgs'.llvmPackages_latest;
                  llvmBuild =
                    if cfg.crossCompile != null then
                      inputs.nixpkgs.legacyPackages.${cfg.crossCompile.host}.llvmPackages_latest
                    else
                      inputs.nixpkgs4.legacyPackages.${pkgs.stdenv.hostPlatform.system}.llvmPackages_latest;
                in
                prev'.kernel.override {
                  buildPackages = pkgs'.buildPackages // {
                    inherit (llvmBuild) stdenv;
                  };

                  inherit (llvmTarget) stdenv;
                  inherit (pkgs') pkgsBuildBuild;

                  ignoreConfigErrors = true;

                  extraMakeFlags = [
                    "LLVM=1"
                    "CC=${llvmBuild.clang-unwrapped}/bin/clang"
                    "LD=${llvmBuild.lld}/bin/ld.lld"
                    "AR=${llvmBuild.llvm}/bin/llvm-ar"
                    "NM=${llvmBuild.llvm}/bin/llvm-nm"
                    "STRIP=${llvmBuild.llvm}/bin/llvm-strip"
                    "OBJCOPY=${llvmBuild.llvm}/bin/llvm-objcopy"
                    "OBJDUMP=${llvmBuild.llvm}/bin/llvm-objdump"
                    "READELF=${llvmBuild.llvm}/bin/llvm-readelf"
                    "KCFLAGS=-DAMD_PRIVATE_COLOR"
                  ];

                  argsOverride =
                    let
                      version = "7.1-git";
                    in
                    {
                      inherit version;
                      modDirVersion = "7.1.0";
                      src = final.fetchFromGitHub {
                        owner = "torvalds";
                        repo = "linux";
                        rev = "1a3746ccbb0a97bed3c06ccde6b880013b1dddc1";
                        hash = "sha256-4k0PM3tRIY0li+IAJUG9A4tMkJcEDUu8Ha9tsUTKcmc=";
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
            LTO_CLANG_FULL y
            CFI y
            UBSAN y
            UBSAN_TRAP y
            UBSAN_BOUNDS y
            UBSAN_BOOL n
            UBSAN_ENUM n
            BTRFS_EXPERIMENTAL y
          ''
          + lib.optionalString (pkgs.stdenv.hostPlatform.system == "aarch64-linux") ''
            CORESIGHT n
            CORESIGHT_SOURCE_ETM4X n
          '';
        }
        {
          name = "O3";
          patch = pkgs.fetchpatch {
            url = "https://github.com/CachyOS/linux/commit/c24fe6d7154676e8df601e3ae54072032899f562.patch";
            hash = "sha256-pHAjHrseUs5xEmNSqgBmTZlC0mb8cMHuYvMRzFvlxQ4=";
          };
          extraConfig = ''
            CC_OPTIMIZE_FOR_PERFORMANCE_O3 y
          '';
        }
        {
          name = "xe stutter fix";
          patch = patch /linux/v5_20260505_matthew_brost_mm_drm_ttm_drm_xe_avoid_reclaim_eviction_loops_under_fragmentation.patch;
        }
        {
          name = "kcompressd";
          patch = pkgs.fetchpatch {
            url = "https://raw.githubusercontent.com/firelzrd/kcompressd-unofficial/refs/heads/main/patches/stable/0001-linux7.1-rc1-kcompressd-unofficial-0.5.patch";
            hash = "sha256-eb7teGa9HXfyLMqdn5aO3YNelCz69ipoVvIRe2e49ic=";
          };
        }
        {
          name = "le9uo";
          patch = patch /linux/le9uo-1.15.patch;
        }
        {
          name = "nouveau detach fix";
          patch = patch /linux/nouveau-detach-fix.patch;
        }
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        {
          name = "x86_64 levels";
          patch = pkgs.fetchpatch {
            url = "https://github.com/CachyOS/linux/commit/b24e97ea653f29ffa815221e4e5a60cc51e61c24.patch";
            hash = "sha256-05q30EQmS+EUL/DTeDVefGAMf+0zfNueJ5aEIyN4OU0=";
          };
          extraConfig = ''
            X86_64_VERSION 3
          '';
        }
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "aarch64-linux") [
        {
          name = "disable panthor";
          patch = null;
          extraConfig = ''
            DRM_PANTHOR n
          '';
        }
      ];
    };

    boot.kernelParams = [ "cfi=kcfi" ];
  };
}
