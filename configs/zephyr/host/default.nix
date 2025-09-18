{
  system,
  inputs,
  module,
  pkg,
  config,
  pkgs,
  ...
}:
{
  imports = [
    (module /cpu/intel.nix)
    (module /gpu/intel.nix)
    (import (module /gpu/nvidia.nix) { platform = "intel"; })
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
    };

    kernelModules = [
      "vfio-pci"
      "kvmfr"
      "ec_sys"
      "ntsync"
    ];

    kernelParams = [
      "modprobe.blacklist=nouveau"
      "kvmfr.static_size_mb=32"
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
        "compress-force=zstd:1"
        "noatime"
      ];
    };

    "/boot" = {
      device = "/dev/nvme0n1p1";
      fsType = "vfat";
      options = [ "noatime" ];
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
    };

    supergfxd.enable = false;
  };

  environment = {
    sessionVariables.MESA_VK_DEVICE_SELECT = "8086:7d51!";

    systemPackages = with pkgs; [
      virtiofsd
      plasma-panel-colorizer
      freerdp
      inputs.winapps.packages.${system}.winapps
      inputs.winapps.packages.${system}.winapps-launcher
    ];
  };
}
