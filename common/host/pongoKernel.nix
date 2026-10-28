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
            llvmBuild =
              if cfg.crossCompile != null then
                inputs.nixpkgs.legacyPackages.${cfg.crossCompile.host}.llvmPackages_latest
              else
                inputs.nixpkgs-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.llvmPackages_latest;
            basePkgs =
              if cfg.crossCompile != null then
                inputs.nixpkgs-kernel.legacyPackages.${cfg.crossCompile.host}.pkgsCross.${cfg.crossCompile.target}
              else
                inputs.nixpkgs-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system};
            pkgs' = basePkgs.extend (
              final: prev: {
                rust-bindgen-unwrapped = prev.rust-bindgen-unwrapped.override {
                  clang = llvmBuild.clang;
                };
              }
            );
          in
          pkgs'.linuxPackages_testing.extend (
            final': prev': {
              kernel =
                let
                  llvmTarget = pkgs'.llvmPackages_latest;
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
                      modDirVersion = "7.3.0";
                      src = pkgs.fetchFromGitHub {
                        owner = "torvalds";
                        repo = "linux";
                        rev = "d135ab453a7400a34930bdda1ef4bdc8acfac80e";
                        hash = "sha256-rK+BaJJbaAXLqzH4GgQPkFN1gq3O6wtxKMxMXzw1Rig=";
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
            CFI y
            UBSAN y
            UBSAN_TRAP y
            UBSAN_BOUNDS y
            UBSAN_BOOL n
            UBSAN_ENUM n
            BTRFS_EXPERIMENTAL y
            DEBUG_INFO_BTF_INLINE n
            ANDROID_BINDER_IPC_RUST y
            # Clang 23 FORTIFY false positive in gud_connector_add_tv_mode().
            DRM_GUD n
          '';
        }
        {
          name = "O3";
          patch = pkgs.fetchpatch {
            url = "https://github.com/CachyOS/linux/commit/12d17b523d3a3e2c59bf125f5ea6f2efbd585ff3.patch";
            hash = "sha256-IBMUlm2U9wMxpHviCXbFXzRawhl1KH8EOIQoajo7CJ0=";
          };
          extraConfig = ''
            CC_OPTIMIZE_FOR_PERFORMANCE_O3 y
          '';
        }
        {
          name = "nouveau detach fix";
          patch = patch /linux/nouveau-detach-fix.patch;
        }
        {
          name = "sched: topology-aware cache scheduling";
          patch = patch /linux/v2_20260827_wujianyong_sched_scale_cache_aware_aggregation_at_llc_granularity_rebased.patch;
          extraConfig = ''
            SCHED_CACHE y
          '';
        }
        {
          name = "drm/sched fair policy fixups";
          patch = patch /linux/20260814_tvrtko_ursulin_drm_sched_fair_policy_fixups.patch;
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
          name = "lib/lz4: stop forking upstream LZ4, vendor it";
          patch = patch /linux/v1_20260925_michal_wilczynski_lib_lz4_stop_forking_upstream_lz4_vendor_it.patch;
        }
        {
          name = "fuse: enable large folios";
          patch = patch /linux/20260916_joanne_koong_fuse_enable_large_folios.patch;
        }
        {
          name = "sched: improving latency of short slice tasks (rebased)";
          patch = patch /linux/v2_20261002_vincent_guittot_improving_latency_of_short_slice_tasks_rebased.patch;
        }
        {
          name = "sched: short slice re-anchors for the newer base";
          patch = patch /linux/20261023_vincent_short_slice_reanchors.patch;
        }
        {
          name = "mm/mglru: frequency guided promotion (MGLRU-FG)";
          patch = patch /linux/v4_20261015_kairui_song_mm_mglru_frequency_guided_promotion_and_flag_cleanup.patch;
        }
        {
          name = "zram: redesign zcomp and rework backends (rebased)";
          patch = patch /linux/20261009_sergey_senozhatsky_zram_redesign_zcomp_and_rework_backends_rebased.patch;
        }
        {
          name = "mm/zswap: batch the writeback IO";
          patch = patch /linux/20261007_alexandre_ghiti_mm_zswap_batch_the_writeback_io.patch;
        }
        {
          name = "mm: read the page cache without folio references (RFC v1)";
          patch = patch /linux/20261019_kiryl_shutsemau_mm_read_page_cache_without_folio_references.patch;
        }
        {
          name = "mm/page_alloc: defrag_mode retries follow promoted requests";
          patch = patch /linux/20261027_mm_page_alloc_defrag_mode_retries.patch;
        }
        {
          name = "mm/page_alloc: no reclaim stalls for costly __GFP_NORETRY";
          patch = patch /linux/20261027_mm_page_alloc_noretry_costly_orders.patch;
        }
        {
          name = "mm/vmalloc: keep drain_vmap_work off vmap metadata cache lines";
          patch = patch /linux/20261027_mm_vmalloc_drain_work_cacheline.patch;
        }
        {
          name = "mm/vma: avoid spurious write locks when read-locking";
          patch = patch /linux/20261027_mm_vma_avoid_spurious_write_locks.patch;
        }
        {
          name = "net: preserve shared-frag annotation, keep ESP out of shared frags";
          patch = patch /linux/20261023_net_preserve_shared_frags.patch;
        }
        /*
          {
            name = "android: restore the legacy C binder driver";
            patch = patch /linux/20261026_binder_restore_legacy_c_driver.patch;
          }
        */
      ]
      ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        {
          name = "x86_64 levels";
          patch = patch /linux/20260831_eric_naim_arch_x86_add_x86_64_isa_and_zen4_compiler_optimizations_rebased.patch;
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
            DRM_MSM n
            DRM_POWERVR n
          '';
        }
      ];

      kernelParams = [ "cfi=kcfi" ];
    }
    // {
      #extraModulePackages = [ adios ];

      #kernelModules = [ "adios" ];

      #extraModprobeConfig = "alias adios-iosched adios";
    };
  };
}
