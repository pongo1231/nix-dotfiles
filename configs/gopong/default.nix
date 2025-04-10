{
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
      "compress-force=zstd:6"
    ];
  };

  networking.networkmanager.enable = lib.mkForce false;


  users = {
    users.habbo = {
      isNormalUser = true;
      home = "/home/habbo";
      extraGroups = [ "podman" ];
      hashedPassword = "$y$j9T$okA7Iq1HvpZz9jhUnm4kz.$yX/qF3P.WElXbCAZph5p/qSQ7BDOaX4j4l/3bh3ZjyB";
    };
  };
}
