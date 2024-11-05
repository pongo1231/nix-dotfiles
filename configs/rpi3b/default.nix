{ lib
, ...
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

    kernelParams = [ "preempt=none" ];
  };

  zramSwap.memoryPercent = lib.mkForce 400;

  networking = {
    networkmanager.enable = lib.mkForce false;
    wireless.iwd.enable = true;
  };
}
