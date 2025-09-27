{
  withSecrets,
  config,
  lib,
  ...
}:
{
  imports = [
    ./webserver.nix
  ];

  boot = {
    initrd.availableKernelModules = [
      "ata_piix"
      "virtio_pci"
      "virtio_scsi"
      "xhci_pci"
      "sd_mod"
      "sr_mod"
    ];

    loader = {
      systemd-boot.enable = lib.mkForce false;
      grub = {
        enable = true;
        device = "/dev/sda";
      };
    };
  };

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "btrfs";
    options = [
      "noatime"
      "lazytime"
      "compress-force=zstd:1"
    ];
  };

  networking.networkmanager.enable = lib.mkForce false;

  users.users = {
    stuff = {
      isNormalUser = true;
      extraGroups = [
        "podman"
        "nginx"
      ];
      hashedPasswordFile = config.sops.secrets."base/userPassword".path;
      linger = true;
    };
  };
}
