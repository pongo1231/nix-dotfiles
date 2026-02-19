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
          version = "26.1-git";

          src = pkgs.fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "mesa";
            repo = "mesa";
            rev = "05ef9f01a7cf411935ba664729ea487f6e0f4d0d";
            hash = "sha256-LHiVfui372g9TIglGx5x1Dq5Lr6xZO+tCS0tbHoyD/Q=";
          };

          patches = builtins.filter (p: !lib.strings.hasInfix "musl" p) prev.patches ++ [
            (pkgs.fetchpatch {
              url = "https://gitlab.com/evlaV/mesa/-/commit/e682bb001fc4e85ab191c1557692ebad5a4ee8af.patch";
              hash = "sha256-E5GItsdehLHxkgSUPQgfZxv67/+YVoTyMDr1738hq9Y=";
            })
          ];

          NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
        });
  };
}
