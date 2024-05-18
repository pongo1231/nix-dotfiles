{ config
, lib
, pkgs
, modulesPath
, ...
}:
{
  imports = [
    ../amd.nix
    (import ../nvidia.nix { platform = "amd"; })
    ../tlp.nix
    ../libvirt.nix
    (import ../samba.nix { sharePath = "/home/pongo/Public"; })
  ];

  boot = {
    initrd = {
      luks.devices."root" =
        {
          device = "/dev/disk/by-uuid/70a791df-646a-4684-81e3-4e943778296f";
          allowDiscards = true;
          bypassWorkqueues = true;
        };
      availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" ];
    };
    kernelPackages = lib.mkForce (pkgs.kernel.linuxPackages_testing.extend
      (finalAttrs: prevAttrs: {
        hp-omen-linux-module = finalAttrs.callPackage ../../pkgs/hp-omen-linux-module { };
      }));
    kernelPatches = [
      {
        name = "dgpu passthrough fix";
        patch = null;
        extraConfig = ''
          HSA_AMD_SVM n
        '';
      }
    ];
    kernelModules = [ "vfio-pci" "kvmfr" "ec_sys" ];
    kernelParams = [
      "amdgpu.dcdebugmask=0x10"
      "amdgpu.ppfeaturemask=0xffffffff"
      "vfio_pci.ids=10de:22bd" # dgpu audio
      "kvmfr.static_size_mb=32"
    ];

    extraModulePackages = with config.boot.kernelPackages; [
      kvmfr
      hp-omen-linux-module
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/e4c4c179-e254-46a3-b28a-acec2ce1775f";
      fsType = "btrfs";
      options = [ "compress-force=zstd:6" "noatime" ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/7651-3774";
      fsType = "vfat";
    };
  };

  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  programs.fish = {
    shellAliases = {
      nvstatus = "cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status";
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="kvmfr", OWNER="pongo", GROUP="wheel", MODE="0600"
  '';

  systemd = {
    services.amdctl-undervolt = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "idle";
        ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.amdctl}/bin/amdctl -p0 -v124 && ${pkgs.amdctl}/bin/amdctl -p1 -v124 && ${pkgs.amdctl}/bin/amdctl -p2 -v124'";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    looking-glass-client
    virtiofsd
  ];
}
