{
  config,
  pkgs,
  lib,
  ...
}:
{
  services = {
    displayManager.sddm = {
      enable = lib.mkDefault true;
      wayland.enable = lib.mkDefault true;
      autoNumlock = lib.mkDefault true;
    };

    desktopManager.plasma6.enable = lib.mkDefault true;
  };

  environment.systemPackages =
    with pkgs;
    with pkgs.kdePackages;
    [
      kcmutils
      kdeconnect-kde
      sddm-kcm
      flatpak-kcm
      kate
      ark
      kcalc
      ocs-url
      krfb # for the "Virtual Display" button in kde connect to work
      maliit-keyboard
      qtstyleplugin-kvantum

      # for KDE info center
      clinfo
      glxinfo
      vulkan-tools
      wayland-utils
      aha
      dmidecode
    ];
}
