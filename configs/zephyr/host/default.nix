{
  module,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    (module /cpu/intel.nix)
    (import (module /gpu) [
      "intel"
      "nvidia"
    ])
    (module /libvirt.nix)
    (import (module /samba.nix) { sharePath = "/home/pongo/Public"; })
    (import (module /snapper.nix) { additionalSubvols = [ "/run/media/ssd2" ]; })
    (module /printing.nix)
  ];

  boot = {
    initrd = {
      luks.devices."root" = {
        device = "/dev/disk/by-partlabel/NixOS";
        allowDiscards = true;
        bypassWorkqueues = true;
      };

      availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "vmd"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
    };

    kernelModules = [
      "vfio-pci"
      "ntsync"
    ];

    kernelParams = [
      #"i915.force_probe=!7d51"
      #"xe.force_probe=7d51"
      #"irqaffinity=14,15"
    ];

    extraModulePackages =
      with config.boot.kernelPackages;
      let
        mod =
          pkg:
          pkg.overrideAttrs (prev: {
            makeFlags = prev.makeFlags ++ kernel.extraMakeFlags;
          });
      in
      [
        (mod kvmfr)
      ];

    binfmt.emulatedSystems = [
      "aarch64-linux"
    ];
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

    "/run/media/ssd2" = {
      device = "/dev/disk/by-partlabel/SSD2";
      fsType = "btrfs";
      options = [
        "x-systemd.device-timeout=5"
        "nofail"
        "noatime"
        "lazytime"
        "compress-force=zstd"
      ];
    };
  };

  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;

  services = {
    udev.extraRules = ''
      SUBSYSTEM=="kvmfr", OWNER="pongo", GROUP="wheel", MODE="0600"
    '';

    sunshine = {
      enable = true;
      package = pkgs.sunshine;
      capSysAdmin = true;
      autoStart = false;
    };

    asusd = {
      enable = true;
      enableUserService = true;
    };

    supergfxd.enable = false;

    howdy = {
      enable = true;
      control = "sufficient";
    };

    beesd.filesystems = {
      "-" = {
        spec = "/";
        extraOptions = [ "-c 1" ];
      };

      "ssd2" = {
        spec = "/run/media/ssd2";
        hashTableSizeMB = 512;
        extraOptions = [ "-c 1" ];
      };
    };

    keyd = {
      enable = true;
      keyboards.laptop = {
        ids = [
          "0b05:19b6:85a3e4e4"
        ];
        settings.main = {
          "leftshift+leftmeta+f23" = "S-f10";
        };
      };
    };

    scx-loader.settings.default_sched = "scx_bpfland";
  };

  systemd.services = {
    "enable-ksm".script =
      "${pkgs.util-linux}/bin/taskset -pc 14,15 $(${pkgs.procps}/bin/pgrep -x ksmd)";
  }
  // lib.mapAttrs' (
    name: fs:
    lib.nameValuePair "beesd@${name}" {
      serviceConfig.AllowedCPUs = "14,15";
    }
  ) config.services.beesd.filesystems;

  environment = {
    sessionVariables = {
      MESA_VK_DEVICE_SELECT = "8086:7d51!";
      KWIN_DRM_ALLOW_INTEL_COLORSPACE = 1;
      KWIN_DRM_ALLOW_NVIDIA_COLORSPACE = 1;
      KWIN_FORCE_ASSUME_HDR_SUPPORT = 1;
    };

    systemPackages = with pkgs; [
      virtiofsd
      plasma-panel-colorizer
      freerdp
      snapperS
    ];
  };
}
