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
          device = "/dev/disk/by-uuid/5539a54b-6a8b-4c42-ade9-a589f12efdb9";
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
      device = "/dev/disk/by-uuid/fe6befe3-433a-43a0-8e5d-e4128c68b05f";
      fsType = "btrfs";
      options = [ "compress-force=zstd:6" "noatime" ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/37EB-F1C4";
      fsType = "vfat";
    };
  };

  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  programs.fish = {
    shellAliases = {
      nvstatus = "cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status";
    };
  };
}
