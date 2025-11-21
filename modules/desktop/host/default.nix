{
  inputs,
  patch,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.lsfg-vk.nixosModules.default

    ./mesa_git.nix
  ];

  boot = {
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

    lsfg-vk = {
      enable = true;
      package = (pkgs.callPackage "${inputs.lsfg-vk}/lsfg-vk.nix" { }).overrideAttrs (prev: {
        src = pkgs.fetchFromGitHub {
          owner = "PancakeTAS";
          repo = "lsfg-vk";
          rev = "ff1a0f72a7d6d08b84d58b7b4dc5f05c9f904f98";
          hash = "sha256-d1x90BUgQAHPn0yK8K833lvmeleQyTi2MmWy3vKW+v4=";
          fetchSubmodules = true;
        };
      });
    };
  };

  virtualisation.waydroid.enable = true;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
  };

  environment.systemPackages = with pkgs; [
    #systemdgenie
    waypipe
  ];
}
