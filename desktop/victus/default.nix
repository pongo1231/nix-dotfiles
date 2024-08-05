{ config
, lib
, pkgs
, modulesPath
, inputs
, ...
}:
{
  imports = [
    ../amd.nix
    (import ../nvidia.nix { platform = "amd"; })
    ../tlp.nix
    ../libvirt.nix
    (import ../samba.nix { sharePath = "/home/pongo/Public"; })
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
              version = "6.11-rc2";
              modDirVersion = "6.11.0-rc2";
              /*src = pkgs.fetchgit {
                url = "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git";
                rev = "defaf1a2113a22b00dfa1abc0fd2014820eaf065";
                hash = "sha256-Az2sLF7gIjEa6R/vAVExdLxLj5YM9viU6L+Q9qFahdo=";
              };*/
              src = pkgs.fetchzip {
                url = "https://git.kernel.org/torvalds/t/linux-${version}.tar.gz";
                hash = "sha256-+nfCerBqzOtf3xYVQfXA24r557V7v0Pe9J9p/R0DXOs=";
              };
            };
          });
          hp-omen-linux-module = finalAttrs.callPackage ../../pkgs/hp-omen-linux-module { };
        }));
    kernelPatches = [
      {
        name = "dgpu passthrough fix";
        patch = null;
        extraConfig = ''
          HSA_AMD_SVM n
        '';
      }
      {
        name = "no-latency-multiplier";
        patch = pkgs.fetchpatch {
          url = "https://lore.kernel.org/linux-pm/20240728192659.58115-1-qyousef@layalina.io/t.mbox";
          hash = "sha256-kDKpSmZflv0B0023W35Gm9F3D8BYfiltLOrDMxQS23s=";
          # from https://gist.github.com/al3xtjames/a9aff722b7ddf8c79d6ce4ca85c11eaa
          decode = pkgs.writeShellScript "decodeMbox" ''
            export PATH="${lib.makeBinPath [ pkgs.git ]}:$PATH"
            export XDG_DATA_HOME="$TMPDIR"
            gzip -dc | ${pkgs.b4}/bin/b4 -n --offline-mode am -m - -o -
          '';
        };
      }
      /*{
        name = "fast-cppc";
        patch = pkgs.fetchpatch {
          url = "https://lore.kernel.org/linux-pm/e717feea3df0a178a9951491040a76c79a00556c.1716649578.git.Xiaojian.Du@amd.com/t.mbox";
          hash = "sha256-csR9oBePEhB5J9bTpZUHd0qyU9gopspvaXvIUJDAfdY=";
          # from https://gist.github.com/al3xtjames/a9aff722b7ddf8c79d6ce4ca85c11eaa
          decode = pkgs.writeShellScript "decodeMbox" ''
            export PATH="${lib.makeBinPath [ pkgs.git ]}:$PATH"
            export XDG_DATA_HOME="$TMPDIR"
            gzip -dc | ${pkgs.b4}/bin/b4 -n --offline-mode am -m - -o -
          '';
        };
      }
      {
        name = "fast-aes-gcm";
        patch = pkgs.fetchpatch {
          url = "https://lore.kernel.org/lkml/20240602222221.176625-1-ebiggers@kernel.org/t.mbox";
          hash = "sha256-ijYl+f0x/v52zlelxJWm9/heXqliOPEODX8Xt3w+f5I=";
          # from https://gist.github.com/al3xtjames/a9aff722b7ddf8c79d6ce4ca85c11eaa
          decode = pkgs.writeShellScript "decodeMbox" ''
            export PATH="${lib.makeBinPath [ pkgs.git ]}:$PATH"
            export XDG_DATA_HOME="$TMPDIR"
            gzip -dc | ${pkgs.b4}/bin/b4 -n --offline-mode am -m - -o -
          '';
        };
      }
      {
        name = "6.10 fixups";
        patch = null;
        extraConfig = ''
          DRM_DP_AUX_CHARDEV n
          DRM_DISPLAY_DP_AUX_CHARDEV y

          DRM_DP_CEC n
          DRM_DISPLAY_DP_AUX_CEC y
        '';
      }*/
    ];
    kernelModules = [ "vfio-pci" "kvmfr" "ec_sys" "ryzen_smu" ];
    kernelParams = [
      "amdgpu.dcdebugmask=0x10"
      "amdgpu.ppfeaturemask=0xffffffff"
      #"vfio_pci.ids=10de:22bd" # dgpu audio
      "kvmfr.static_size_mb=32"
      "mitigations=off"
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

  programs.fish = {
    shellAliases = {
      nvstatus = "cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status";
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="kvmfr", OWNER="pongo", GROUP="wheel", MODE="0600"
  '';

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

  environment = {
    systemPackages = with pkgs; [
      looking-glass-client
      virtiofsd
    ];
  };
}
