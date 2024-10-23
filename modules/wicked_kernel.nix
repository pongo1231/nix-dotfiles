{ pkgs, lib, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      linuxPackages_wicked = (final.kernel.linuxPackages_testing.extend (finalAttrs: prevAttrs: {
        kernel = prevAttrs.kernel.override (prevAttrs': {
          #kernelPatches = builtins.filter (x: !lib.hasPrefix "rust" x.name) prevAttrs'.kernelPatches;
          ignoreConfigErrors = true;
          argsOverride =
            let
              version = "6.12-rc4";
            in
            {
              inherit version;
              modDirVersion = "6.12.0-rc4";
              src = pkgs.fetchgit {
                url = "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git";
                rev = "c2ee9f594da826bea183ed14f2cc029c719bf4da";
                hash = "sha256-mtrKclMNMlZ09sIV5KsLg5NS+gi3e9g1LFszgyAIfW0=";
              };
              /*src = pkgs.fetchzip {
                url = "https://git.kernel.org/torvalds/t/linux-${version}.tar.gz";
                hash = "sha256-k0+IByRl5Qp0Q73uF0N2lRJNiPEQV0z9pFmEUu/SJWM=";
              };*/
            };
        });
      }));
    })
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_wicked;

    kernelPatches =
      let
        # from https://gist.github.com/al3xtjames/a9aff722b7ddf8c79d6ce4ca85c11eaa
        decode = pkgs.writeShellScript "
                  decodeMbox " ''
          export PATH="${lib.makeBinPath [ pkgs.git ]}:$PATH"
          export XDG_DATA_HOME="$TMPDIR"
          gzip -dc | ${pkgs.b4}/bin/b4 -n --offline-mode am -m - -o -
        '';
      in
      [
        /*{
          name = "dgpu passthrough fix";
          patch = null;
          extraConfig = ''
            HSA_AMD_SVM n
          '';
        }*/
        {
          name = "Fix 6.12 build";
          patch = null;
          extraConfig = ''
            I2C_DESIGNWARE_PLATFORM m
          '';
        }
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
          patch = ../../patches/linux/drm-fixes-2024-09-06.patch;
         }*/
        /*{
          name = "shrink-file-struct";
          patch = ../../patches/linux/shrink-file-struct.patch;
        }*/
        /*{
          name = "bore-6.11";
          patch = pkgs.fetchpatch {
            url = "https://raw.githubusercontent.com/firelzrd/bore-scheduler/refs/heads/main/patches/testing/linux-6.11-bore/0001-linux6.11.y-bore5.3.0-rc4.patch";
            hash = "sha256-nm+IxyxbsKKueJBLbkkrY7raI64MRnwV0g5WwXQSMF0=";
          };
        }*/
        {
          name = "preempt-lazy";
          patch = pkgs.fetchpatch {
            url = "https://lore.kernel.org/all/20241007074609.447006177@infradead.org/t.mbox";
            hash = "sha256-S455vwyf9cnLMHquE2CnFg3n/2VCa5+C3ukZpiK2gLg=";
            inherit decode;
          };
          extraConfig = ''
            PREEMPT_LAZY y
          '';
        }
        {
          name = "preempt-lazy2";
          patch = pkgs.fetchpatch {
            url = "https://lore.kernel.org/lkml/20241009105709.887510-1-bigeasy@linutronix.de/t.mbox";
            hash = "sha256-np95Cl2zWMgwj3ZmtwvtcnLyMMc3Zm8bvoaeCG+l99I=";
            inherit decode;
          };
        }
        {
          name = "lightweight-guard-pages";
          patch = ../patches/linux/6.12/lightweight-guard-pages.patch;
        }
        {
          name = "crypto-optimizations";
          patch = ../patches/linux/6.12/crypto-optimizations.patch;
        }
        {
          name = "amd-color-management";
          patch = pkgs.fetchpatch {
            url = "https://github.com/CachyOS/linux/commit/53c3930779ba776a6a4a7ea215fd7a3d225353b3.patch";
            hash = "sha256-/ji6JF5gOY/wyaiT39kXKyWTbCMyI0CAvbvgQgWORnk=";
          };
          extraConfig = ''
            AMD_PRIVATE_COLOR y
          '';
        }
        {
          name = "jupiter-mfd";
          patch = ../patches/linux/6.12/jupiter-mfd.patch;
          extraConfig = ''
            LEDS_STEAMDECK m
            EXTCON_STEAMDECK m
            MFD_STEAMDECK m
            SENSORS_STEAMDECK m
          '';
        }
      ];
  };
}
