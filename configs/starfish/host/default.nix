{
  modulesPath,
  ...
}:
{
  imports = [ "${modulesPath}/profiles/qemu-guest.nix" ];

  boot = {
    initrd = {
      availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "xen_blkfront"
        "vmw_pvscsi"
      ];

      kernelModules = [ "nvme" ];
    };

    loader = {
      systemd-boot.enable = false;

      efi.canTouchEfiVariables = false;

      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        device = "nodev";
      };
    };
  };

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/7040-3D0F";
      fsType = "vfat";
    };

    "/" = {
      device = "/dev/sda1";
      fsType = "ext4";
    };
  };
}
