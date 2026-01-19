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
            rev = "1c98532e15bdbf8c3ae953b1cd6bc4a59c9a2cea";
            hash = "sha256-9ZPySI8L1oAA9XvQtl2JeLk7OM04lF5nR+MEnVddATo=";
          };

          patches = builtins.filter (p: !lib.strings.hasInfix "musl" p) prev.patches ++ [
            (patch /mesa/26/trav_separate_compilation_ra.patch)
          ];

          NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
        });
    extraPackages = with pkgs; [ intel-media-driver ];
  };
}
