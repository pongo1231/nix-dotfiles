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
    (module /cpu/amd.nix)
    (import (module /gpu/nvidia.nix) { platform = "amd"; })
    (module /libvirt.nix)
    (import (module /samba.nix) { sharePath = "/home/pongo/Public"; })
  ];

  boot = {
    initrd = {
      luks.devices."root" = {
        device = "/dev/disk/by-uuid/70a791df-646a-4684-81e3-4e943778296f";
        allowDiscards = true;
        bypassWorkqueues = true;
      };

      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usb_storage"
        "sd_mod"
      ];
    };

    kernelModules = [
      "vfio-pci"
      "kvmfr"
      "ec_sys"
      "ntsync"
    ];

    kernelParams = [
      #"amdgpu.dcdebugmask=0x10"
      "modprobe.blacklist=nouveau"
      "kvmfr.static_size_mb=32"
    ];

    extraModulePackages =
      with config.boot.kernelPackages;
      let
        llvmMod =
          pkg: pkg
        /*
          .overrideAttrs (
            final: prev: {

                inherit (kernel) stdenv;
                makeFlags = (prev.makeFlags or [ ]) ++ [
                  "LLVM=1"
                  "CC=${final.stdenv.cc}/bin/clang"
                ];
                hardeningDisable = [ "strictoverflow" ];
            }
          )
        */
        ;
      in
      [
        (llvmMod kvmfr)

        (llvmMod (callPackage (pkg /hp-omen-linux-module) { }))
      ];

    binfmt.emulatedSystems = [
      "aarch64-linux"
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/e4c4c179-e254-46a3-b28a-acec2ce1775f";
      fsType = "btrfs";
      options = [
        "compress-force=zstd:1"
        "noatime"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/7651-3774";
      fsType = "vfat";
      options = [ "noatime" ];
    };
  };

  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  services = {
    udev.extraRules = ''
      SUBSYSTEM=="kvmfr", OWNER="pongo", GROUP="wheel", MODE="0600"
    '';

    keyd = {
      enable = true;
      keyboards.main.settings = {
        alt = {
          kp1 = "end";
          kp2 = "down";
          kp3 = "pagedown";
          kp4 = "left";
          kp6 = "right";
          kp7 = "home";
          kp8 = "up";
          kp9 = "pageup";
          kp0 = "insert";
          kpdot = "delete";
        };
      };
    };

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
  };

  environment = {
    sessionVariables.MESA_VK_DEVICE_SELECT = "1002:15bf!";

    systemPackages = with pkgs; [
      virtiofsd
      plasma-panel-colorizer
      freerdp
      inputs.winapps.packages.${system}.winapps
      inputs.winapps.packages.${system}.winapps-launcher
    ];
  };
}
