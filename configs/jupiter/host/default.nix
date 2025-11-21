{
  inputs,
  module,
  patch,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.jovian.nixosModules.default
    inputs.lsfg-vk.nixosModules.default

    (module /cpu/amd.nix)
    (import (module /gpu) [ "amd" ])

    ./steam.nix
  ];

  boot = {
    initrd = {
      luks.devices = {
        root = {
          device = "/dev/nvme0n1p2";
          allowDiscards = true;
          bypassWorkqueues = true;
        };
      };

      unl0kr.enable = true;

      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "sdhci_pci"
      ];
    };

    kernelModules = [ "ntsync" ];

    kernelParams = [ "mitigations=off" ];

    plymouth.enable = false;
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

    "/run/media/mmcblk0p1" = {
      device = "/dev/mmcblk0p1";
      fsType = "btrfs";
      options = [
        "x-systemd.device-timeout=5"
        "nofail"
        "noatime"
        "lazytime"
        "compress-force=zstd"
        "autodefrag"
      ];
    };
  };

  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  networking.hostId = "a1f92a1f";

  services = {
    displayManager = {
      sddm.enable = false;
      gdm.enable = false;
    };

    fstrim.enable = true;

    sunshine = {
      enable = true;
      package = pkgs.sunshine;
      capSysAdmin = true;
      autoStart = false;
    };

    lsfg-vk = {
      enable = true;
      package = (pkgs.callPackage "${inputs.lsfg-vk}/lsfg-vk.nix" { }).overrideAttrs (prev: {
        src = pkgs.fetchFromGitHub {
          owner = "PancakeTAS";
          repo = "lsfg-vk";
          rev = "0a6455a3815e4a417a54fd312987d2e2320f2684";
          hash = "sha256-gt8IS+H24nFqqxo+I3kZHysMiyIQryYYOuMcB3DJmq0=";
          fetchSubmodules = true;
        };
      });
    };

    beesd.filesystems = {
      "-" = {
        spec = "/";
        hashTableSizeMB = 256;
        extraOptions = [ "-c 1" ];
      };

      "mmcblk0p1" = {
        spec = "/run/media/mmcblk0p1";
        hashTableSizeMB = 128;
        extraOptions = [ "-c 1" ];
      };
    };
  };

  /*
    systemd = {
      services.greetd.serviceConfig.MemoryKSM = true;
      user.services.gamescope-session.serviceConfig.MemoryKSM = true;
    };
  */

  environment.systemPackages = with pkgs; [ steamdeck-firmware ];
}
