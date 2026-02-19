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

    ./bluetooth.nix
    ./mesa.nix
  ];

  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ ];

    plymouth.enable = lib.mkDefault true;
  };

  hardware = {
    enableRedistributableFirmware = true;

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
          rev = "d9cdcf8ba78b2e104eda3a8d66673c4b30a9fb71";
          hash = "sha256-j8zAI72f4uF0JuVFOqnXrgNd/MHYhi9hOEzt07ftV94=";
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
