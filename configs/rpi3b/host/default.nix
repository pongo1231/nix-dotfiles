{
  pkgs,
  ...
}:
{
  fileSystems."/" = {
    device = "/dev/mmcblk0p2";
    fsType = "ext4";
    options = [
      "noatime"
      "lazytime"
    ];
  };

  boot = {
    loader = {
      systemd-boot.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    kernelParams = [ "mitigations=off" ];
  };

  networking = {
    networkmanager.enable = false;
    wireless.iwd.enable = true;
  };

  environment.systemPackages = with pkgs; [ btrfs-progs ];
}
