{
  pkgs,
  lib,
  ...
}:
{
  fileSystems."/" = {
    device = "/dev/mmcblk0p2";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      generic-extlinux-compatible.enable = true;
    };
  };

  networking = {
    networkmanager.enable = lib.mkForce false;
    wireless.iwd.enable = true;
  };

  environment.systemPackages = with pkgs; [ btrfs-progs ];
}
