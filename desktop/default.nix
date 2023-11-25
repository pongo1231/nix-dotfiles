{ config
, pkgs
, lib
, ...
}:
{
  boot = {
    kernelPackages = lib.mkDefault pkgs.kernel.linuxPackages_latest;
    extraModulePackages = with config.boot.kernelPackages; lib.mkDefault [ xpadneo ];
    plymouth.enable = lib.mkDefault true;
  };

  services = {
    xserver = {
      displayManager.sddm = {
        enable = lib.mkDefault true;
        wayland.enable = true;
        autoNumlock = true;
      };
      desktopManager.plasma5.enable = true;
    };
  };
}
