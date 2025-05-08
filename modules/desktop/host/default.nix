{
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

  pongo.boot.useFullPreempt = true;

  services = {
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

  environment.systemPackages = with pkgs; [ systemdgenie ];
}
