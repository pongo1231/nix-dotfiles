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
          device = "/dev/disk/by-uuid/ac2b73ac-bae8-4345-8951-36a0ee38e2f1";
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
      device = "/dev/disk/by-uuid/d685db49-ec70-4854-9949-4da35a09ad31";
      fsType = "btrfs";
      options = [
        "compress-force=zstd:1"
        "noatime"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/0573-D9FE";
      fsType = "vfat";
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

    lsfg-vk.enable = true;
  };

  /*
    systemd = {
      services.greetd.serviceConfig.MemoryKSM = true;
      user.services.gamescope-session.serviceConfig.MemoryKSM = true;
    };
  */

  environment = {
    sessionVariables = {
      ENABLE_LSFG = 1;
    };

    systemPackages = with pkgs; [
      steamdeck-firmware
      mangohud
      gamescope
      (pkgs.writeShellScriptBin "lsfg2x" ''
        exec env LEGACY_LSFG=1 LSFG_PERFORMANCE_MODE=1 "$@"
      '')
      (pkgs.writeShellScriptBin "lsfg3x" ''
        exec env LEGACY_LSFG=1 LSFG_PERFORMANCE_MODE=1 LSFG_MULTIPLIER=3 "$@"
      '')
      (pkgs.writeShellScriptBin "lsfg4x" ''
        exec env LEGACY_LSFG=1 LSFG_PERFORMANCE_MODE=1 LSFG_MULTIPLIER=4 "$@"
      '')
    ];
  };
}
