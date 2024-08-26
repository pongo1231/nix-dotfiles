{ config
, lib
, pkgs
, modulesPath
, ...
}:
{
  boot = {
    kernelPackages = pkgs.kernel.linuxPackages_latest;
    initrd.availableKernelModules = [ "ata_piix" "virtio_pci" "virtio_scsi" "xhci_pci" "sd_mod" "sr_mod" ];
    loader = {
      systemd-boot.enable = lib.mkForce false;
      grub = {
        enable = true;
        device = "/dev/sda";
      };
    };
  };

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/73d20b49-f05c-4d6a-9cf6-f6d6c90a54a2";
      fsType = "btrfs";
      options = [ "noatime" "compress-force=zstd:6" ];
    };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "gopong.dev" = {
        forceSSL = true;
        enableACME = true;
        root = "/srv/http";
      };

      "chaos.gopong.dev" = {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass = "https://gopong.dev:9907";
      };

      "habbo.gopong.dev" = {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass = "https://gopong.dev:8081";
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "pongo1999712@gmail.com";
  };

  users = {
    users.habbo = {
      isNormalUser = true;
      home = "/home/habbo";
      extraGroups = [ "podman" ];
      hashedPassword = "$y$j9T$okA7Iq1HvpZz9jhUnm4kz.$yX/qF3P.WElXbCAZph5p/qSQ7BDOaX4j4l/3bh3ZjyB";
    };
  };
}
