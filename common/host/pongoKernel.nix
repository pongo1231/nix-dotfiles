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
                      modDirVersion = "7.3.0";
                      src = pkgs.fetchFromGitHub {
                        owner = "torvalds";
                        repo = "linux";
                        rev = "734bef548a96e8774d6eef5dfa2026c6edc4e80b";
                        hash = "sha256-cGFhYRUlA1rrNm8JEUsVTm4TNCwp+CElwiTeqjExX7Y=";
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
            url = "https://github.com/CachyOS/linux/commit/12d17b523d3a3e2c59bf125f5ea6f2efbd585ff3.patch";
            hash = "sha256-IBMUlm2U9wMxpHviCXbFXzRawhl1KH8EOIQoajo7CJ0=";
          };
          extraConfig = ''
            CC_OPTIMIZE_FOR_PERFORMANCE_O3 y
          '';
        }
        {
          name = "mm: the whole mm-new queue (wholesale)";
          patch = patch /linux/20261020_mm-queue_mm-new_wholesale.patch;
        }
        {
          name = "mm: mm-new queue re-anchors for the newer base";
          patch = patch /linux/20261023_mm-queue_reanchors.patch;
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
          name = "iommu/amd: PerfOpt IOMMU performance optimization support";
          patch = patch /linux/v2_20260908_mario_limonciello_iommu_performance_optimization_support.patch;
        }
        {
          name = "iommu/amd: Make PerfOpt compulsory";
          patch = patch /linux/20261012_mario_limonciello_iommu_amd_make_perfopt_compulsory.patch;
        }
        {
          name = "batch lookups in follow_page_mask()";
          patch = patch /linux/v3_20260810_riel_batch_lookups_in_follow_page_mask.patch;
        }
        {
          name = "mm/slub: refill prefilled sheaves from the barn";
          patch = patch /linux/20260921_hao_li_mm_slub_refill_prefilled_sheaves_from_the_barn.patch;
        }
        {
          name = "mm/memory_hotplug: make shrink_zone_span() more robust";
          patch = patch /linux/20260920_david_hildenbrand_mm_memory_hotplug_make_shrink_zone_span_more_robust.patch;
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
          name = "assoc_array fixes";
          patch = patch /linux/20261012_torvalds_assoc-array-fixes.patch;
        }
        {
          name = "mm: read the page cache without folio references (RFC v1)";
          patch = patch /linux/20261019_kiryl_shutsemau_mm_read_page_cache_without_folio_references.patch;
        }
        {
          name = "ext4: dev branch (whole branch)";
          patch = patch /linux/20261020_tytso_ext4_dev.patch;
        }
        {
          name = "net: preserve shared-frag annotation, keep ESP out of shared frags";
          patch = patch /linux/20261023_net_preserve_shared_frags.patch;
        }
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
