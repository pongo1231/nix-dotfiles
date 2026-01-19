{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.lsfg-vk.nixosModules.default

    ./mesa.nix
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
          rev = "e1f89cc1daed469cd6e1a21a18e5816fea9ec9fb";
          hash = "sha256-9f1epUbJNr8yaUfWNcVth88UfGP1kRX6+yOcA/60XL8=";
          fetchSubmodules = true;
        };

        postPatch = ''
          #substituteInPlace lsfg-vk-layer/VkLayer_LSFGVK_frame_generation.json.in --replace-fail "liblsfg-vk.so" "$out/lib/liblsfg-vk.so"
        '';

        cmakeFlags = [
          (lib.cmakeFeature "LSFGVK_LAYER_LIBRARY_PATH" "${placeholder "out"}/lib/liblsfg-vk-layer.so")
        ];
      });
    };
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
      waypipe
    ]
    ++ (import ../lsfgScripts.nix pkgs);
}
