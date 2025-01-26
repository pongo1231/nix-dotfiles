{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  boot = {
    kernelParams = [
      "threadirqs"
      "rcu_nocbs=0-N"
    ];

    extraModulePackages = with config.boot.kernelPackages; [ ];

    plymouth.enable = lib.mkDefault true;
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    xpadneo.enable = true;
  };

  services = {
    displayManager.sddm = {
      enable = lib.mkDefault true;
      wayland.enable = true;
      autoNumlock = true;
    };
    desktopManager.plasma6.enable = true;
    xserver.xkb.layout = "de";

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    flatpak.enable = true;

    seatd.enable = true;

    fwupd.enable = true;
  };

  virtualisation.waydroid.enable = true;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
  };

  environment.systemPackages =
    with pkgs;
    with pkgs.kdePackages;
    [
      kdePackages.kcmutils
      kdePackages.kdeconnect-kde
      sddm-kcm
      flatpak-kcm
      kate
      ark
      kcalc
      ocs-url
      krfb # for the "Virtual Display" button in kde connect to work
      maliit-keyboard
      kdePackages.qtstyleplugin-kvantum
      systemdgenie

      # for KDE info center
      clinfo
      glxinfo
      vulkan-tools
      wayland-utils
      aha
      dmidecode
    ];
}
