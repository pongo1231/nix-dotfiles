{ config
, pkgs
, ...
}: {
  imports = [
    ../../modules/nbfc-linux

    ../intel.nix
    (import ../nvidia.nix { platform = "intel"; })
    ../tlp.nix
    ../samba.nix
    ../libvirt.nix
    (import ../samba.nix { sharePath = "/media/ssd/public"; })

    ./gpu_passthrough.nix
    ./snapper.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [ "kvm-intel" "kvmgt" "vfio-iommu-type1" "mdev" ];
    };
  };

  fileSystems = {
    "/" = {
      device = "root/root";
      fsType = "zfs";
    };

    "/home" = {
      device = "root/home";
      fsType = "zfs";
    };

    "/nix" = {
      device = "root/nix";
      fsType = "zfs";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/D98C-6807";
      fsType = "vfat";
    };
  };

  powerManagement.cpuFreqGovernor = "powersave";

  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;

  networking.hostId = "77d11187";

  programs.fish = {
    shellAliases = {
      nvstatus = "cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status";
      turbo_off = "echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo";
      turbo_on = "echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo";
    };
  };

  services = {
    undervolt = {
      enable = true;
      coreOffset = -90;
      gpuOffset = -90;
      uncoreOffset = -90;
      analogioOffset = -90;
    };

    nbfc-linux.enable = true;

    thermald.enable = true;

    udev.extraHwdb = ''                                         
      evdev:input:b0011v0001p0001*
      KEYBOARD_KEY_F5=prog1
      KEYBOARD_KEY_F6=power
    '';
  };

  virtualisation.podman.enableNvidia = true;

  environment.systemPackages = with pkgs; [

  ];
}
