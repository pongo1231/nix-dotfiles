{
  inputs,
  patch,
  pkg,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.pongo.pongoKernel;

  adios = pkgs.callPackage (pkg /adios-iosched) {
    kernel = config.boot.kernelPackages.kernel;
    inherit (config.boot.kernelPackages) kernelModuleMakeFlags;
  };
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
                inputs.nixpkgs-kernel.legacyPackages.${cfg.crossCompile.host}.pkgsCross.${cfg.crossCompile.target}
              else
                inputs.nixpkgs-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system};
          in
          pkgs'.linuxPackages_testing.extend (
            final': prev': {
              kernel =
                let
                  llvm =
                    if cfg.crossCompile != null then
                      inputs.nixpkgs-kernel.legacyPackages.${cfg.crossCompile.host}.llvmPackages_latest
                    else
                      inputs.nixpkgs-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.llvmPackages_latest;
                  llvmTarget = pkgs'.llvmPackages_latest;
                  llvmBuild =
                    if cfg.crossCompile != null then
                      inputs.nixpkgs.legacyPackages.${cfg.crossCompile.host}.llvmPackages_latest
                    else
                      inputs.nixpkgs-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.llvmPackages_latest;
                in
                prev'.kernel.override {
                  inherit (llvmTarget) stdenv;
                  inherit (pkgs') pkgsBuildBuild;

                  ignoreConfigErrors = true;

                  extraMakeFlags = [
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
                      version = "7.3-git";
                    in
                    {
                      inherit version;
                      modDirVersion = "7.3.0-rc3";
                      src = pkgs.fetchFromGitHub {
                        owner = "torvalds";
                        repo = "linux";
                        rev = "9b87fdc9af2fbfcdb5c24a64139685ef80f6573f";
                        hash = "sha256-gu4sw3BOQX1Nqtg3T90uOxXOp4O1GPJyR7U85Zvwgig=";
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
            AD4130 n
            BINFMT_MISC_BPF y
            DRM_GUD n
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
          name = "kcompressd";
          patch = patch /linux/kcompressd-final.patch;
        }
        {
          name = "le9uo";
          patch = patch /linux/le9uo-1.15.patch;
        }
        {
          name = "nouveau detach fix";
          patch = patch /linux/nouveau-detach-fix.patch;
        }
        {
          name = "sched: topology-aware cache scheduling";
          patch = patch /linux/20260625_wujianyong_sched_extend_cache_aware_scheduling_into_topology_aware_scheduling.patch;
          extraConfig = ''
            SCHED_CACHE y
          '';
        }
        {
          name = "drm/sched fair policy fixups";
          patch = patch /linux/20260814_tvrtko_ursulin_drm_sched_fair_policy_fixups.patch;
        }

        {
          name = "core/entry tip";
          patch = patch /linux/core-entry-tip.patch;
        }
        {
          name = "batch lookups in follow_page_mask()";
          patch = patch /linux/v3_20260810_riel_batch_lookups_in_follow_page_mask.patch;
        }
        {
          name = "zstd: use x86 feature infrastructure for BMI2 dispatch";
          patch = patch /linux/20260901_usama_arif_zstd_use_x86_feature_infrastructure_for_bmi2_dispatch.patch;
        }
        {
          name = "crypto: zstd: avoid initializing the workspace twice";
          patch = patch /linux/20260825_usama_arif_crypto_zstd_avoid_initializing_the_workspace_twice.patch;
        }
        {
          name = "btrfs: zstd: avoid a copy in zstd_decompress_bio()";
          patch = patch /linux/20260904_usama_arif_btrfs_zstd_avoid_a_copy_in_zstd_decompress_bio.patch;
        }
        {
          name = "kbuild: significantly speed up kernel builds";
          patch = patch /linux/20260914_lorenzo_stoakes_kbuild_significantly_speed_up_kernel_builds.patch;
        }
        {
          name = "sched/fair: randomize equally shallow idle CPU picks";
          patch = patch /linux/20260916_christian_loehle_sched_fair_randomize_equally_shallow_idle_cpu_picks.patch;
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
        {
          name = "x86/fpu: check for missing AVX and AVX-512 xstate bits";
          patch = patch /linux/0001-x86-fpu-check-missing-avx.patch;
        }
        {
          name = "um: check for missing AVX and AVX-512 xstate bits";
          patch = patch /linux/0002-um-check-missing-avx.patch;
        }
        {
          name = "crypto: x86 - stop using cpu_has_xfeatures()";
          patch = patch /linux/0003-crypto-x86-stop-using-cpu_has_xfeatures.patch;
        }
        {
          name = "lib/crypto: x86 - stop using cpu_has_xfeatures()";
          patch = patch /linux/0004-lib-crypto-x86-stop-using-cpu_has_xfeatures.patch;
        }
        {
          name = "lib/crc: x86 - stop using cpu_has_xfeatures()";
          patch = patch /linux/0005-lib-crc-x86-stop-using-cpu_has_xfeatures.patch;
        }
        {
          name = "x86/fpu: remove cpu_has_xfeatures()";
          patch = patch /linux/0006-x86-fpu-remove-cpu_has_xfeatures.patch;
        }
        {
          name = "xor: remove redundant X86_FEATURE_OSXSAVE check";
          patch = patch /linux/0007-xor-remove-redundant-osxsave-check.patch;
        }
        {
          name = "xor: add AVX-512 optimized xor_gen()";
          patch = patch /linux/0008-xor-add-avx512-xor_gen.patch;
        }
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "aarch64-linux") [
        {
          name = "disable panthor";
          patch = null;
          extraConfig = ''
            DRM_PANTHOR n
            DRM_MSM n
            DRM_POWERVR n
          '';
        }
      ];

      kernelParams = [ "cfi=kcfi" ];

      kernel.sysctl."vm.workingset_protection" = 1;
    }
    // {
      extraModulePackages = [ adios ];

      kernelModules = [ "adios" ];

      extraModprobeConfig = "alias adios-iosched adios";
    };
  };
}
