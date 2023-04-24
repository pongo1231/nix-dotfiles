{ config
, lib
, pkgs
, modulesPath
, ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/bb7eda0c-17b1-4399-a3a0-fa1c72b45877";
    fsType = "btrfs";
    options = [ "subvol=root" "noatime" "compress-force=zstd:6" ];
  };

  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/7d13a11e-2245-4878-bab9-f6372627c0f3";
      allowDiscards = true;
      bypassWorkqueues = true;
    };
  };

  environment.etc."crypttab".text = ''
    ssd     UUID=0b226cbc-287c-41cd-8377-a92a2de416ba       /keyfile    discard,no-read-workqueue,no-write-workqueue
    hdd     UUID=065c2b5a-3b56-478f-b5e0-b3b5c6a78ff1       /keyfile
  '';

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/bb7eda0c-17b1-4399-a3a0-fa1c72b45877";
    fsType = "btrfs";
    options = [ "subvol=home" "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/9575-D217";
    fsType = "vfat";
  };

  fileSystems."/media/ssd" = {
    device = "/dev/disk/by-uuid/31b51531-24cb-4532-aef8-8c866f08e178";
    fsType = "btrfs";
    options = [ "noatime" "compress-force=zstd:6" ];
  };

  fileSystems."/media/hdd" = {
    device = "/dev/disk/by-uuid/c3a302d7-34c8-42c3-98c9-f8e38f0ba245";
    fsType = "btrfs";
    options = [ "noatime" "compress-force=zstd:10" "autodefrag" ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
