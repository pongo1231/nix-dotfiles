{ config
, lib
, pkgs
, modulesPath
, ... }:
{
  imports = [
    ../amd.nix
    (import ../nvidia.nix { platform = "amd"; })
    ../tlp.nix
    ../libvirt.nix
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
    kernelModules = [ "kvm-amd" ];
    kernelPatches = [
      {
        name = "dgpu passthrough fix";
        patch = null;
        extraConfig = ''
          HSA_AMD_SVM n
        '';
      }
    ];
  };

  fileSystems = {
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

  systemd.services.amdctl-undervolt = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.amdctl}/bin/amdctl -m -p0 -v124 && ${pkgs.amdctl}/bin/amdctl -p1 -v124 && ${pkgs.amdctl}/bin/amdctl -p2 -v124'";
    };
  };
}
