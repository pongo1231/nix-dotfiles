{
  system,
  inputs,
  module,
  patch,
  pkg,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    (module /amdcpu.nix)
    (import (module /nvidia.nix) { platform = "amd"; })
    (module /libvirt.nix)
    (import (module /samba.nix) { sharePath = "/home/pongo/Public"; })
    (module /wicked_kernel.nix)
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
      "ryzen_smu"
    ];

    kernelParams = [
      "amdgpu.dcdebugmask=0x10"
      "modprobe.blacklist=nouveau"
      "kvmfr.static_size_mb=32"
    ];

    extraModulePackages = with config.boot.kernelPackages; [
      (kvmfr.overrideAttrs (
        finalAttrs: prevAttrs: {
          src = pkgs.fetchFromGitHub {
            owner = "gnif";
            repo = "LookingGlass";
            rev = "e25492a3a36f7e1fde6e3c3014620525a712a64a";
            hash = "sha256-efAO7KLdm7G4myUv6cS1gUSI85LtTwmIm+HGZ52arj8=";
          };
          patches = [ (patch /kvmfr/string-literal-symbol-namespace.patch) ];
        }
      ))
      #(callPackage (pkg /hp-omen-linux-module) { })
      (ryzen-smu.overrideAttrs (
        finalAttrs: prevAttrs: {
          patches = (prevAttrs.patches or [ ]) ++ [ (patch /ryzen-smu/phoenix-new-pm-table-version.patch) ];
        }
      ))
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
        "compress-force=zstd:6"
        "noatime"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/7651-3774";
      fsType = "vfat";
    };
  };

  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  programs.fish.shellAliases = {
    nvstatus = "cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status";
  };

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
      package = inputs.nixpkgs-master.legacyPackages.${system}.sunshine;
      capSysAdmin = true;
      autoStart = false;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      virtiofsd
      (kde-rounded-corners.overrideAttrs (
        finalAttrs: prevAttrs: {
          src = pkgs.fetchFromGitHub {
            owner = "matinlotfali";
            repo = "KDE-Rounded-Corners";
            rev = "53980a5dd5d0a24422cdd9aaea84c3b3ebcab545";
            hash = "sha256-6uSgYFY+JV8UCy3j9U/hjk6wJpD1XqpnXBqmKVi/2W0=";
          };
        }
      ))
      freerdp
      inputs.winapps.packages.${system}.winapps
      inputs.winapps.packages.${system}.winapps-launcher
    ];
  };
}
