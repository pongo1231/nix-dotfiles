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
            rev = "5a3b0ce461247a3164c6c58df1d6a701db1baa83";
            hash = "sha256-BgtQPwqzJxLPpeYQMD14a9MgXYEvedV0/88stibg2DM=";
          };

          patches = builtins.filter (p: !lib.strings.hasInfix "musl" p) prev.patches;

          NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
        });
    extraPackages = with pkgs; [ intel-media-driver ];
  };
}
