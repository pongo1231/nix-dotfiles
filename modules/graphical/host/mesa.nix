{
  patch,
  pkgs,
  lib,
  ...
}:
{
  hardware.graphics = {
    enable = true;
    package =
      (pkgs.mesa.override {
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
      }).overrideAttrs
        (prev: {
          version = "26.0-git";

          src = pkgs.fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "mesa";
            repo = "mesa";
            rev = "ca1d59d813972911a3a523713445ced7d758713e";
            hash = "sha256-eQtdaMpO9kZJUxPnAnQx3kuGzCkOQBsvoPAOPcIoJy4=";
          };

          patches = builtins.filter (p: !lib.strings.hasInfix "musl" p) prev.patches ++ [
            (patch /mesa/26/trav_separate_compilation_ra.patch)
          ];

          NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
        });
    extraPackages = with pkgs; [ intel-media-driver ];
  };
}
