{
  withSecrets,
  module,
  config,
  pkgs,
  lib,
  ...
}:
withSecrets "pongo" { } { "base/userPassword" = { }; }
// {
  imports = [
    (module /snapper.nix)

    ./webserver.nix
    ./postgresql.nix
    ./webserver.nix
    ./mailserver.nix
    ./nextcloud.nix
    ./vaultwarden.nix
    #./discourse.nix
    #./gitlab.nix
    ./hastebin.nix
    ./picsur.nix
    ./findmydevice.nix
    ./mollysocket.nix
    ./karakeep.nix
    ./firefox-syncserver.nix
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
      "compress-force=zstd"
    ];
  };

  networking = {
    fqdn = "ecmec.eu";

    networkmanager.enable = lib.mkForce false;
  };

  users.users = {
    stuff = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets."base/userPassword".path;
      linger = true;
    };

    habbo = {
      isNormalUser = true;
      hashedPassword = "$y$j9T$okA7Iq1HvpZz9jhUnm4kz.$yX/qF3P.WElXbCAZph5p/qSQ7BDOaX4j4l/3bh3ZjyB";
      linger = true;
    };
  };

  services.beesd.filesystems."-" = {
    spec = "/";
    hashTableSizeMB = 128;
    extraOptions = [ "-c 1" ];
  };

  environment.systemPackages = with pkgs; [ snapperS ];
}
