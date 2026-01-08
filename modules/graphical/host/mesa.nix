{
  inputs,
  patch,
  pkgs,
  lib,
  ...
}:
{
  hardware.graphics = {
    enable = true;
    package =
      (pkgs.mesa.override ({
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
      })).overrideAttrs
        (prev: {
          src = pkgs.fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "mesa";
            repo = "mesa";
            rev = "c939744d2daafb6d62a1aeec1d101aefe2fe67c7";
            sha256 = "sha256-RRITa1mU9NCZzAcekx7D1L+AroyWvrYEuIsC7HzL8Gc=";
          };

          patches = prev.patches ++ [
            (patch /mesa/26/radv-rt-1d-dispatch.patch)
          ];

          NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
        });
    extraPackages = with pkgs; [ intel-media-driver ];
  };
}
