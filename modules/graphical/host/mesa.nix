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
          src = pkgs.fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "mesa";
            repo = "mesa";
            rev = "8ed244755420e59758af893f934eb6c438627377";
            sha256 = "sha256-PnYDW16lUWqxvK4FDsoWkZZ6Opc/a0cLBxmEdgLTyhI=";
          };

          patches = builtins.filter (p: !lib.strings.hasInfix "musl" p) prev.patches ++ [
            (patch /mesa/26/trav_separate_compilation_ra.patch)
          ];

          NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
        });
    extraPackages = with pkgs; [ intel-media-driver ];
  };
}
