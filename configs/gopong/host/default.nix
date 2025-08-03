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
    device = "/dev/disk/by-uuid/73d20b49-f05c-4d6a-9cf6-f6d6c90a54a2";
    fsType = "btrfs";
    options = [
      "noatime"
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
