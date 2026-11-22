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

  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  environment.systemPackages = with pkgs; [
    gnome-tweaks

    gnomeExtensions.caffeine
    clipboard-indicator
    gnomeExtensions.desktop-icons-ng-ding
    gnomeExtensions.gsconnect
    gnomeExtensions.removable-drive-menu
    gnomeExtensions.vitals

    adjust-display-brightness
    appindicator-tooltip
    dash-to-panel-patched
    display-per-monitor
  ];
}
