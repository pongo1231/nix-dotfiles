{
  module,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    (module /cpu/amd.nix)
    (import (module /gpu) [
      "amd"
      #"nvidia"
    ])
    (module /libvirt.nix)
    #(import (module /samba.nix) { sharePath = "/home/pongo/Public"; })
    (import (module /snapper.nix) { })
    (module /printing.nix)
  ];

  boot = {
    initrd = {
      luks.devices."root" = {
        device = "/dev/disk/by-partlabel/NixOS";
        allowDiscards = true;
        bypassWorkqueues = true;
      };

      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usb_storage"
        "sd_mod"
      ];
    };

    binfmt.emulatedSystems = [
      "aarch64-linux"
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [
        "noatime"
        "lazytime"
        "compress-force=zstd"
      ];
    };

    "/boot" = {
      device = "/dev/nvme0n1p1";
      fsType = "vfat";
      options = [
        "noatime"
        "lazytime"
      ];
    };
  };

  services = {
    udev.extraRules = ''
      SUBSYSTEM=="kvmfr", OWNER="pongo", GROUP="wheel", MODE="0600"
    '';

    sunshine = {
      enable = true;
      capSysAdmin = true;
      autoStart = false;
    };

    asusd.enable = true;

    beesd.filesystems."-" = {
      spec = "/";
      hashTableSizeMB = 1024;
      extraOptions = [ "-c 1" ];
    };
  };
}
