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
          "nouveau"
        ];

        vulkanDrivers = [
          "amd"
          "gfxstream"
          "intel"
          "microsoft-experimental"
          "swrast"
          "virtio"
          "nouveau"
        ];

        libdrm = pkgs.libdrm.overrideAttrs {
          version = "2.4.133";
          src = pkgs.fetchurl {
            url = "https://dri.freedesktop.org/libdrm/libdrm-2.4.133.tar.xz";
            hash = "sha256-/Gj50LoupjyUMqKZ4U/qCfrXqKZugDn814AspZ93tPU=";
          };
        };
      }).overrideAttrs
        (prev: {
          version = "26.1-git";

          src = pkgs.fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "mesa";
            repo = "mesa";
            rev = "e824c30460449da57a67919d606415cf3e17cd87";
            hash = "sha256-AhVn2226oRwoycJaFpRHwi+0zajMmxrt1dTDjry2k00=";
          };

          patches = prev.patches ++ [
            (pkgs.fetchpatch {
              url = "https://gitlab.com/evlaV/mesa/-/commit/e682bb001fc4e85ab191c1557692ebad5a4ee8af.patch";
              hash = "sha256-E5GItsdehLHxkgSUPQgfZxv67/+YVoTyMDr1738hq9Y=";
            })
          ];
        });
  };
}
