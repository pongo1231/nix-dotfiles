{
  modulesPath,
  ...
}:
{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  boot = {
    initrd = {
      availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "sr_mod"
        "virtio_blk"
      ];

      kernelModules = [ "kvm-amd" ];
    };

    loader = {
      systemd-boot.enable = false;
      grub = {
        enable = true;
        device = "/dev/vda";
      };
    };

    kernelParams = [ "mitigations=off" ];
  };

  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "btrfs";
    options = [
      "noatime"
      "lazytime"
      "compress-force=zstd:6"
    ];
  };

  networking.networkmanager.enable = false;

  services.beesd.filesystems."-" = {
    spec = "/";
    hashTableSizeMB = 32;
    extraOptions = [ "-c 1" ];
  };

  programs.mosh.enable = true;
}
