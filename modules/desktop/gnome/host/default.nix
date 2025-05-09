{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.xserver = {
    displayManager.gdm.enable = lib.mkDefault true;
    desktopManager.gnome.enable = lib.mkDefault true;
  };
}
