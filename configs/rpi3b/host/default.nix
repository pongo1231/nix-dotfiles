{
  pkgs,
  lib,
  ...
}:
{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  boot = {
    loader = {
      systemd-boot.enable = lib.mkForce false;
      generic-extlinux-compatible.enable = true;
    };
  };

  nix.package = pkgs.nixVersions.git;

  networking = {
    networkmanager.enable = lib.mkForce false;
    wireless.iwd.enable = true;
  };

  environment.systemPackages = with pkgs; [ btrfs-progs ];
}
