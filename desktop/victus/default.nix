{ config
, lib
, pkgs
, modulesPath
, inputs
, ...
}:
{
  imports = [
    inputs.chaotic.nixosModules.default

    ../amd.nix
    (import ../nvidia.nix { platform = "amd"; })
    ../tlp.nix
    ../libvirt.nix
    (import ../samba.nix { sharePath = "/home/pongo/Public"; })
  ];

  nixpkgs.overlays = [
    (final: prev: {
      kdePackages = prev.kdePackages.overrideScope (finalScope: prevScope: {
        /*kwin = prevScope.kwin.overrideAttrs (finalAttrs: prevAttrs: {
          src = final.fetchgit {
            url = "https://invent.kde.org/plasma/kwin.git";
            rev = "4f03404fb3ebebf416f2af33f06a0b9b8c5eae65";
            hash = "sha256-oA3DOKJf6B6Jmm+wGvI4k6zvoMISh5N8lfAeST62ql0=";
          };

          postPatch = prevAttrs.postPatch + ''
            substituteInPlace src/wayland/CMakeLists.txt --replace "PRIVATE_CODE" "\"\""
            substituteInPlace src/wayland/tools/CMakeLists.txt --replace "PRIVATE_CODE" "\"\""
          '';

          buildInputs = prevAttrs.buildInputs ++ [
            final.libcanberra
            (prevScope.plasma-wayland-protocols.overrideAttrs (prevAttrs: {
              src = final.fetchgit {
                url = "https://invent.kde.org/libraries/plasma-wayland-protocols.git";
                rev = "f8915796a606f672fb3f456cde782f66d1adfa14";
                hash = "sha256-KC1ocnCLF2fMUX4MkRs2spHwPbZc91j4ALBPzF/ahDw=";
              };
            }))
          ];
        });*/
      });
    })
  ];

  boot = {
    initrd = {
      luks.devices."root" =
        {
          device = "/dev/disk/by-uuid/70a791df-646a-4684-81e3-4e943778296f";
          allowDiscards = true;
          bypassWorkqueues = true;
        };
      availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" ];
    };

    kernelPackages = lib.mkForce
      (pkgs.kernel.linuxPackages_testing.extend
        (finalAttrs: prevAttrs: {
          kernel = prevAttrs.kernel.override (prevAttrs': {
            #kernelPatches = builtins.filter (x: !lib.hasPrefix "rust" x.name) prevAttrs'.kernelPatches;
            ignoreConfigErrors = true;
            argsOverride = rec {
              version = "6.11";
              modDirVersion = "6.11.0";
              /*src = pkgs.fetchgit {
                url = "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git";
                rev = "2004cef11ea072838f99bd95cefa5c8e45df0847";
                hash = "sha256-9qkixflnBQ3KRuqsX3ewqnNtC4J4d+S3iDtUzO5FfFw=";
              };*/
              src = pkgs.fetchzip {
                url = "https://git.kernel.org/torvalds/t/linux-${version}.tar.gz";
                hash = "sha256-QIbHTLWI5CaStQmuoJ1k7odQUDRLsWNGY10ek0eKo8M=";
              };
            };
          });
          hp-omen-linux-module = finalAttrs.callPackage ../../pkgs/hp-omen-linux-module { };
        }));

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
          name = "no-latency-multiplier";
          patch = pkgs.fetchpatch {
            url = "https://lore.kernel.org/linux-pm/20240728192659.58115-1-qyousef@layalina.io/t.mbox";
            hash = "sha256-kDKpSmZflv0B0023W35Gm9F3D8BYfiltLOrDMxQS23s=";
            inherit decode;
          };
        }
        /*{
          name = "amdgpu-perf-fix";
          patch = ../../patches/linux/drm-fixes-2024-09-06.patch;
         }*/
        {
          name = "shrink-file-struct";
          patch = ../../patches/linux/shrink-file-struct.patch;
        }
        {
          name = "bore-6.11";
          patch = pkgs.fetchpatch {
            url = "https://raw.githubusercontent.com/firelzrd/bore-scheduler/refs/heads/main/patches/testing/linux-6.11-bore/0001-linux6.11.y-bore5.3.0-rc4.patch";
            hash = "sha256-nm+IxyxbsKKueJBLbkkrY7raI64MRnwV0g5WwXQSMF0=";
          };
        }
      ];

    kernelModules = [ "vfio-pci" "kvmfr" "ec_sys" "ryzen_smu" ];

    kernelParams = [
      "amdgpu.dcdebugmask=0x10"
      #"amdgpu.ppfeaturemask=0xffffffff"
      "modprobe.blacklist=nouveau"
      #"vfio_pci.ids=10de:22bd" # dgpu audio
      "kvmfr.static_size_mb=32"
    ];

    extraModulePackages = with config.boot.kernelPackages; [
      (kvmfr.overrideAttrs (prevAttrs: {
        patches = (prevAttrs.patches or [ ]) ++ [ ../../patches/kvmfr/6.10.patch ];
      }))
      hp-omen-linux-module
      ryzen-smu
    ];
  };

  fileSystems =
    {
      "/" = {
        device = "/dev/disk/by-uuid/e4c4c179-e254-46a3-b28a-acec2ce1775f";
        fsType = "btrfs";
        options = [ "compress-force=zstd:6" "noatime" ];
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/7651-3774";
        fsType = "vfat";
      };
    };

  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  programs.fish.shellAliases = {
    nvstatus = "cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status";
  };

  services = {
    udev.extraRules = ''
      SUBSYSTEM=="kvmfr", OWNER="pongo", GROUP="wheel", MODE="0600"
    '';

    keyd = {
      enable = true;
      keyboards.main.settings = {
        alt = {
          kp1 = "end";
          kp2 = "down";
          kp3 = "pagedown";
          kp4 = "left";
          kp6 = "right";
          kp7 = "home";
          kp8 = "up";
          kp9 = "pageup";
          kp0 = "insert";
          kpdot = "delete";
        };
      };
    };
  };

  # binding this too early to snd_hda_intel breaks unbinding later (for vfio passthrough)
  # work around this silly bug by binding it to vfio-pci first and then rebinding it to snd_hda_intel
  /*systemd = {
          services.dgpu-audio-to-snd_hda_intel = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c 'echo 0000:01:00.1 > /sys/bus/pci/drivers/vfio-pci/unbind && echo 0000:01:00.1 > /sys/bus/pci/drivers/snd_hda_intel/bind'";
      };
          };
        };*/

  #chaotic.mesa-git.enable = true;

  environment = {
    systemPackages = with pkgs; [
      looking-glass-client
      virtiofsd
      kde-rounded-corners
    ];
  };
}

