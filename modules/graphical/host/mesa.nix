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
          version = "26.0-git";

          src = pkgs.fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "mesa";
            repo = "mesa";
            rev = "a3ec5ece8b89694554a23bd0653edea35561481d";
            hash = "sha256-RQUOssZNlh0lMPmyLIJLErt1nmHoIOe+E4j/9qZ8fvA=";
          };

          patches = builtins.filter (p: !lib.strings.hasInfix "musl" p) prev.patches;

          NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
        });
    extraPackages = with pkgs; [ intel-media-driver ];
  };
}
