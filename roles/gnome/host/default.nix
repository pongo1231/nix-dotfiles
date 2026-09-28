{
  pkgs,
  lib,
  ...
}:
{
  services = {
    displayManager.gdm.enable = lib.mkDefault true;
    desktopManager.gnome.enable = lib.mkDefault true;
  };

  environment.systemPackages = with pkgs; [
    gnome-tweaks
  ];
}
