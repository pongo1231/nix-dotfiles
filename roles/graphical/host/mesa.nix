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
            rev = "63c47734a9093c9b3649d247a9ae21a9ef2de321";
            hash = "sha256-7L5D1ewiOeu9RoQ9QHkrFcmzAIS0Yr+FoulwMOeBy5k=";
          };

          patches = builtins.filter (p: !lib.strings.hasInfix "musl" p) prev.patches ++ [
            (pkgs.fetchpatch {
              url = "https://gitlab.com/evlaV/mesa/-/commit/e682bb001fc4e85ab191c1557692ebad5a4ee8af.patch";
              hash = "sha256-E5GItsdehLHxkgSUPQgfZxv67/+YVoTyMDr1738hq9Y=";
            })
          ];

          #NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
        });
  };
}
