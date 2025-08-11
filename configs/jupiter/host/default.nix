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

    kernelModules = [
      "ntsync"
    ];

    plymouth.enable = false;
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [
        "compress-force=zstd:1"
        "noatime"
      ];
    };

    "/boot" = {
      device = "/dev/nvme0n1p1";
      fsType = "vfat";
      options = [ "noatime" ];
    };

    "/run/media/mmcblk0p1" = {
      device = "/dev/mmcblk0p1";
      fsType = "btrfs";
      options = [
        "x-systemd.device-timeout=5"
        "nofail"
        "noatime"
        "compress-force=zstd:1"
      ];
    };
  };

  hardware = {
    cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

    graphics =
      let
        patchMesa =
          mesa:
          mesa.overrideAttrs (prev: {
            patches = prev.patches ++ [
              (patch /mesa/25.0.0/gamescope-limiter.patch)
            ];
          });
      in
      {
        package = lib.mkForce (patchMesa pkgs.mesa);
        package32 = lib.mkForce (patchMesa pkgs.pkgsi686Linux.mesa);
      };
  };

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
          rev = "e22d173999b0f333611a9333f0a709df8269d236";
          hash = "sha256-KfD/UcDaxlUX/y7pP6hA4fwyfgRA7xjOjxvgY3UWHEg=";
          fetchSubmodules = true;
        };
      });
    };
  };

  /*
    systemd = {
      services.greetd.serviceConfig.MemoryKSM = true;
      user.services.gamescope-session.serviceConfig.MemoryKSM = true;
    };
  */

  environment.systemPackages = with pkgs; [
    steamdeck-firmware
    (pkgs.writeShellScriptBin "lsfg2x" ''
      exec env LSFG_LEGACY=1 LSFG_PERFORMANCE_MODE=1 LSFG_MULTIPLIER=2 "$@"
    '')
    (pkgs.writeShellScriptBin "lsfg3x" ''
      exec env LSFG_LEGACY=1 LSFG_PERFORMANCE_MODE=1 LSFG_MULTIPLIER=3 "$@"
    '')
    (pkgs.writeShellScriptBin "lsfg4x" ''
      exec env LSFG_LEGACY=1 LSFG_PERFORMANCE_MODE=1 LSFG_MULTIPLIER=4 "$@"
    '')
  ];
}
