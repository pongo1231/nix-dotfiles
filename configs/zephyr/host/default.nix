{
  system,
  inputs,
  module,
  pkg,
  patch,
  config,
  pkgs,
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
  ];

  boot = {
    initrd = {
      luks.devices."root" = {
        device = "/dev/nvme0n1p2";
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

      prepend = [
        "${./ssdt-sound.cpio}"
      ];
    };

    kernelModules = [
      "vfio-pci"
      "ntsync"
    ];

    kernelParams = [
      "modprobe.blacklist=nouveau"
      #"i915.force_probe=!7d51"
      #"xe.force_probe=7d51"
      "i915.enable_dpcd_backlight=1"
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
        "compress-force=zstd:1"
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

    printing.enable = true;

    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    asusd = {
      enable = true;
      enableUserService = true;
      package = pkgs.asusctl.overrideAttrs (prev: {
        patches = (prev.patches or [ ]) ++ [
          (patch /asusctl/2025.patch)
        ];
      });
    };
  };

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
      inputs.winapps.packages.${system}.winapps
      inputs.winapps.packages.${system}.winapps-launcher
    ];
  };
}
