{
  patch,
  config,
  pkgs,
  lib,
  ...
}:
{
  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ ];

    plymouth.enable = lib.mkDefault true;
  };

  hardware = {
    graphics =
      let
        patchMesa =
          mesa:
          (mesa.override (
            prev:
            let
              stdenv = prev.buildPackages.llvmPackages_latest.stdenv.override {
                cc = prev.buildPackages.llvmPackages_latest.clang.override {
                  inherit (prev.buildPackages.llvmPackages_latest) bintools;
                };
              };
            in
            {
              buildPackages = prev.buildPackages // {
                inherit stdenv;
              };

              inherit stdenv;

              llvmPackages = prev.buildPackages.llvmPackages_latest // {
                inherit (prev.llvmPackages) libclc;
              };

              spirv-llvm-translator = prev.spirv-llvm-translator.override {
                inherit (prev.buildPackages.llvmPackages_latest) llvm;
              };

              galliumDrivers = [
                "radeonsi"
                "iris"
                "virgl"
                "zink"
                "llvmpipe"
              ];

              vulkanDrivers = [
                "amd"
                "intel"
                "gfxstream"
                "swrast"
                "virtio"
              ];
            }
          )).overrideAttrs
            (prev: {
              NIX_CFLAGS_COMPILE = "-O3 -flto=thin";

              outputs = lib.filter (x: x != "spirv2dxil") prev.outputs;
            });
      in
      {
        enable = true;
        #enable32Bit = true;

        package = lib.mkForce (patchMesa pkgs.mesa);
        #package32 = lib.mkForce (patchMesa pkgs.pkgsi686Linux.mesa);
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
  };

  virtualisation.waydroid.enable = true;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
  };

  environment.systemPackages = with pkgs; [
    systemdgenie
    waypipe
  ];
}
