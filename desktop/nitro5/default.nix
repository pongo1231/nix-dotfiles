{ config
, pkgs
, ...
}: {
  imports = [
    ../../modules/nbfc-linux

    ../intel.nix

    ./gpu_passthrough.nix
    ./libvirt.nix
    ./nvidia.nix
    ./snapper.nix
    ./tlp.nix
  ];

  boot = {
    kernelParams = [
      "intel_iommu=on"
      "i915.enable_guc=3"
      "i915.enable_fbc=1"
      "i915.enable_gvt=1"
      "i915.enable_psr=1"
      "i915.fastboot=1"
    ];
    initrd = {
      availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [ "kvm-intel" "kvmgt" "vfio-iommu-type1" "mdev" ];

      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/7d13a11e-2245-4878-bab9-f6372627c0f3";
          allowDiscards = true;
          bypassWorkqueues = true;
        };
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/bb7eda0c-17b1-4399-a3a0-fa1c72b45877";
      fsType = "btrfs";
      options = [ "subvol=root" "noatime" "compress-force=zstd:10" ];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/bb7eda0c-17b1-4399-a3a0-fa1c72b45877";
      fsType = "btrfs";
      options = [ "subvol=home" "noatime" ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/9575-D217";
      fsType = "vfat";
    };

    "/media/ssd" = {
      device = "/dev/disk/by-uuid/31b51531-24cb-4532-aef8-8c866f08e178";
      fsType = "btrfs";
      options = [ "noatime" "compress-force=zstd:10" ];
    };

    "/media/hdd" = {
      device = "/dev/disk/by-uuid/c3a302d7-34c8-42c3-98c9-f8e38f0ba245";
      fsType = "btrfs";
      options = [ "noatime" "compress-force=zstd:15" "autodefrag" ];
    };
  };

  environment.etc."crypttab".text = ''
    ssd     UUID=0b226cbc-287c-41cd-8377-a92a2de416ba       /keyfile    discard,no-read-workqueue,no-write-workqueue
    hdd     UUID=065c2b5a-3b56-478f-b5e0-b3b5c6a78ff1       /keyfile
  '';

  powerManagement.cpuFreqGovernor = "powersave";

  hardware.cpu.intel.updateMicrocode = config.hardware.enableRedistributableFirmware;

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

  environment.systemPackages = with pkgs; [
    snapperS
  ];
}
