{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./bluetooth.nix
    ./mesa.nix
  ];

  boot = {
    kernelModules = [ "ntsync" ];

    extraModulePackages = with config.boot.kernelPackages; [ ];

    plymouth.enable = lib.mkDefault true;
  };

  hardware = {
    enableRedistributableFirmware = true;

    graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [ lsfg-vk ];
    };

    xpadneo.enable = true;
  };

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

    power-profiles-daemon.enable = true;

    kmscon.hwRender = true;
  };

  virtualisation.waydroid.enable = true;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
  };

  environment.systemPackages =
    with pkgs;
    [
      #systemdgenie
    ]
    ++ (import ../lsfgScripts.nix pkgs);
}
