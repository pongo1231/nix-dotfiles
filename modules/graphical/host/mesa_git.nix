{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.chaotic.nixosModules.default
  ];

  nixpkgs.overlays =
    let
      patchMesa =
        pkg: is32bit:
        (pkg.override (
          prev:
          let
            stdenv = prev.buildPackages.gcc15Stdenv;
          in
          {
            buildPackages = prev.buildPackages // {
              inherit stdenv;
            };
            inherit stdenv;

            galliumDrivers = [
              "d3d12"
              "iris"
              "llvmpipe"
              "radeonsi"
              "virgl"
              "zink"
            ];

            vulkanDrivers = [
              "amd"
              "gfxstream"
              "intel"
              "microsoft-experimental"
              "swrast"
              "virtio"
            ];
          }
        )).overrideAttrs
          {
            NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
          };
    in
    [
      (final: prev: {
        mesa_git = patchMesa prev.mesa_git false;
        mesa32_git = patchMesa prev.mesa32_git true;
      })
    ];

  chaotic.mesa-git = {
    enable = true;
    fallbackSpecialisation = false;
    extraPackages = with pkgs; [ intel-media-driver ];
  };
}
