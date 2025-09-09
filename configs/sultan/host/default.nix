{
  withSecrets,
  config,
  lib,
  ...
}:
withSecrets "pongo" { } { "base/userPassword" = { }; }
// {
  imports = [
    ./snapper.nix
    ./postgresql.nix
    ./webserver.nix
    ./mailserver.nix
    ./nextcloud.nix
    ./vaultwarden.nix
    ./discourse.nix
    ./gitlab.nix
    ./hastebin.nix
    ./picsur.nix
    ./findmydevice.nix
    ./mollysocket.nix
  ];

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "xhci_pci"
    "usbhid"
    "sr_mod"
  ];

  fileSystems = {
    "/" = {
      device = "/dev/sda2";
      fsType = "btrfs";
      options = [
        "noatime"
        "compress-force=zstd:1"
      ];
    };

    "/boot" = {
      device = "/dev/sda1";
      fsType = "vfat";
      options = [ "noatime" ];
    };
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

    habbo = {
      isNormalUser = true;
      extraGroups = [
        "podman"
        "nginx"
      ];
      hashedPassword = "$y$j9T$okA7Iq1HvpZz9jhUnm4kz.$yX/qF3P.WElXbCAZph5p/qSQ7BDOaX4j4l/3bh3ZjyB";
      linger = true;
    };
  };
}
