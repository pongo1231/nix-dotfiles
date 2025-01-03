{ desktop ? true
}:
{ patch
, pkg
, pkgs
, lib
, ...
}:
{
  imports = [
    (pkg /uksmd)
  ];

  nixpkgs.overlays = [
    (final: prev: {
      linuxPackages_wicked = final.kernel.linuxPackages_testing.extend (finalAttrs: prevAttrs: {
        kernel = prevAttrs.kernel.override (prevAttrs': {
          #kernelPatches = builtins.filter (x: !lib.hasPrefix "netfilter-typo-fix" x.name) prevAttrs'.kernelPatches;
          ignoreConfigErrors = true;
          argsOverride =
            let
              version = "6.13-rc5";
            in
            {
              inherit version;
              modDirVersion = "6.13.0-rc5";
              /*src = pkgs.fetchgit {
                url = "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git";
                rev = "059dd502b263d8a4e2a84809cf1068d6a3905e6f";
                hash = "sha256-8s0nj3g58v9SoMgAz3LHqImiljlgWeQ9e8fBUnDg2Us=";
              };*/
              src = pkgs.fetchzip {
                url = "https://git.kernel.org/torvalds/t/linux-${version}.tar.gz";
                hash = "sha256-OQdEQ1LQ6+K2Ba2RJtvgsCpRO0o2kyOxYwB/38bTKgs=";
              };
            };
        });

        xpadneo = prevAttrs.xpadneo.overrideAttrs (finalAttrs': prevAttrs': {
          src = final.fetchFromGitHub {
            owner = "atar-axis";
            repo = "xpadneo";
            rev = "227c101fea112e8b7309aadb736b9a1c4120b126";
            hash = "sha256-fI6gX2p2RaJdKi8bluGjqryg0Zjv8otvDe0Fph72mMw=";
          };

          patches = [ ];

          makeFlags = [
            "-C"
            "${finalAttrs.kernel.dev}/lib/modules/${finalAttrs.kernel.modDirVersion}/build"
            "M=$(sourceRoot)"
            "VERSION=${finalAttrs'.version}"
          ];
        });
      });
    })
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_wicked;

    kernelPatches =
      let
        # from https://gist.github.com/al3xtjames/a9aff722b7ddf8c79d6ce4ca85c11eaa
        decode = pkgs.writeShellScript "decodeMbox" ''
          export PATH="${lib.makeBinPath [ pkgs.git ]}:$PATH"
          export XDG_DATA_HOME="$TMPDIR"
          gzip -dc | ${pkgs.b4}/bin/b4 -n --offline-mode am -m - -o -
        '';
      in
      [
        {
          name = "cachyos";
          patch = patch /linux/6.13/cachyos.patch;
          extraConfig = ''
            AMD_PRIVATE_COLOR y
          '';
        }
        /*{
          name = "dgpu passthrough fix";
          patch = null;
          extraConfig = ''
            HSA_AMD_SVM n
          '';
        }*/
        /*{
          name = "Fix 6.12 build";
          patch = null;
          extraConfig = ''
            I2C_DESIGNWARE_PLATFORM m
          '';
        }*/
        /*{
          name = "no-latency-multiplier";
          patch = pkgs.fetchpatch {
            url = "https://lore.kernel.org/linux-pm/20240728192659.58115-1-qyousef@layalina.io/t.mbox";
            hash = "sha256-kDKpSmZflv0B0023W35Gm9F3D8BYfiltLOrDMxQS23s=";
            inherit decode;
          };
        }*/
        /*{
          name = "amdgpu-perf-fix";
          patch = patch /linux/drm-fixes-2024-09-06.patch;
         }*/
        /*{
          name = "shrink-file-struct";
          patch = patch /linux/shrink-file-struct.patch;
        }*/
        /*{
          name = "bore-6.11";
          patch = pkgs.fetchpatch {
            url = "https://raw.githubusercontent.com/firelzrd/bore-scheduler/refs/heads/main/patches/testing/linux-6.11-bore/0001-linux6.11.y-bore5.3.0-rc4.patch";
            hash = "sha256-nm+IxyxbsKKueJBLbkkrY7raI64MRnwV0g5WwXQSMF0=";
          };
        }*/
        /*{
          name = "preempt-lazy";
          patch = patch /linux/6.12/preempt-lazy.patch;
          extraConfig = ''
            PREEMPT_LAZY y
          '';
        }*/
        /*{
          name = "lightweight-guard-pages";
          patch = patch /linux/6.12/lightweight-guard-pages.patch;
        }*/
        /*{
          name = "crypto-optimizations";
          patch = patch /linux/6.12/crypto-optimizations.patch;
        }*/
        /*{
          name = "psr-fix";
          patch = patch /linux/6.12/0001-drm-amd-display-WIP-increase-vblank-off-delay.patch;
        }*/
        /*{
          name = "buffered-uncached";
          patch = patch /linux/6.12/buffered-uncached.patch;
        }*/
        /*{
          name = "context-switch-optimizations";
          patch = patch /linux/6.12/context-switch-optimizations.patch;
        }*/
        {
          name = "kcore-optimizations";
          patch = patch /linux/6.12/kcore-optimizations.patch;
        }
        /*{
          name = "amd-color-management";
          patch = pkgs.fetchpatch {
            url = "https://github.com/CachyOS/linux/commit/53c3930779ba776a6a4a7ea215fd7a3d225353b3.patch";
            hash = "sha256-/ji6JF5gOY/wyaiT39kXKyWTbCMyI0CAvbvgQgWORnk=";
          };
          extraConfig = ''
            AMD_PRIVATE_COLOR y
          '';
        }*/
        {
          name = "faster-suspend-resume";
          patch = patch /linux/6.12/PATCH-v1-0-5-Optimize-async-device-suspend-resume.patch;
        }
        /*{
          name = "btrfs-6.13-backport-and-buffered-uncached";
          patch = patch /linux/6.12/btrfs-6.13-backport-and-buffered-uncached.patch;
        }*/
        /*{
          name = "crc32c-optimizations";
          patch = patch /linux/6.12/crc32c-optimizations.patch;
        }*/
        /*{
          name = "multigrain-timestamps";
          patch = patch /linux/6.12/multigrain-timestamps.patch;
        }*/
        /*{
          name = "mm-6.13-backport";
          patch = patch /linux/6.12/mm-6.13-backport.patch;
        }*/
        /*{
          name = "net-6.13-backport";
          patch = patch /linux/6.12/net-6.13-backport.patch;
        }
        {
          name = "vfs-6.13-backport";
          patch = patch /linux/6.12/vfs-6.13-backport.patch;
        }
        {
          name = "pm-6.13-backport";
          patch = patch /linux/6.12/pm-6.13-backport.patch;
        }
        {
          name = "pm-6.13-backport-2";
          patch = patch /linux/6.12/pm-6.13-backport-2.patch;
        }
        {
          name = "mm-nonmm-6.13-backport";
          patch = patch /linux/6.12/mm-nonmm-6.13-backport.patch;
        }*/
        /*{
          name = "ext4-6.13-backport";
          patch = patch /linux/6.12/ext4-6.13-backport.patch;
        }*/
        /*{
          name = "fuse-6.13-backport";
          patch = patch /linux/6.12/fuse-6.13-backport.patch;
        }
        {
          name = "futex-optimizations";
          patch = patch /linux/6.12/futex-optimizations.patch;
        }
        {
          name = "modules-optimizations";
          patch = patch /linux/6.12/modules-optimizations.patch;
          extraConfig = ''
            ARCH_HAS_EXECMEM_ROX y
          '';
        }*/
        {
          name = "BORE";
          patch = patch /linux/6.13/0001-linux6.13.y-bore5.9.5.patch;
        }
        {
          name = "mglru-optimizations";
          patch = patch /linux/6.13/mglru-optimizations.patch;
        }
        {
          name = "tlb-invalidation";
          patch = patch /linux/6.13/tlb-invalidation.patch;
        }
        /*{
          name = "aes-gcm-amd";
          patch = patch /linux/6.13/aes-gcm-amd.patch;
        }*/
        {
          name = "uncached-buffered-io-optimizations";
          patch = patch /linux/6.13/uncached-buffered-io-optimizations.patch;
        }
        {
          name = "binder-optimizations";
          patch = patch /linux/6.13/binder-optimizations.patch;
        }
        {
          name = "xhci-improvements";
          patch = patch /linux/6.13/xhci-improvements.patch;
        }
        /*{
          name = "drm-deadline";
          patch = patch /linux/6.13/drm-deadline.patch;
        }*/
        {
          name = "jupiter-mfd";
          patch = patch /linux/6.12/jupiter-mfd.patch;
          extraConfig = ''
            LEDS_STEAMDECK m
            EXTCON_STEAMDECK m
            MFD_STEAMDECK m
            SENSORS_STEAMDECK m
          '';
        }
      ];

    kernelParams = lib.optionals desktop [ "preempt=lazy" ];
  };

  systemd.tmpfiles.rules = [
    "w! /sys/kernel/mm/transparent_hugepage/enabled - - - - always"
    "w! /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
    "w! /sys/kernel/mm/transparent_hugepage/shmem_enabled - - - - always"
    "w! /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - 409"
  ];

  #hardware.xpadneo.enable = lib.mkForce false;
}
