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
            rev = "f234d15924dbc9724379a29cf02ee7796c76b598";
            hash = "sha256-35V1Div8NrAlX+oCkvVOAjsI+Ulcfx/ay8Gey2XkC38=";
          };

          patches = builtins.filter (p: !lib.strings.hasInfix "musl" p) prev.patches;

          NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
        });
  };
}
