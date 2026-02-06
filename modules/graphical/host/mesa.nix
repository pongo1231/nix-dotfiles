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
          #"gfxstream"
          "intel"
          "microsoft-experimental"
          "swrast"
          "virtio"
        ];
      }).overrideAttrs
        (prev: {
          version = "26.1-git";

          src = pkgs.fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "mesa";
            repo = "mesa";
            rev = "efb5ab1e4ba12886a94bd321bbd1010e7c10e5b4";
            hash = "sha256-qfDAdAHIAKyMCUubQjIDQhdwT87QWsnnF9uOcCQbQ74=";
          };

          patches = builtins.filter (p: !lib.strings.hasInfix "musl" p) prev.patches;

          NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
        });
  };
}
