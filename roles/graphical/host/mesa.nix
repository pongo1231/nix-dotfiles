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
            rev = "f38f0f51111262306c5e22e1416d85f0e99ab02e";
            hash = "sha256-n8nH4VO5/tRd2X35hCOJ/ZMnaJkSzfP6PUzqXHeoIUE=";
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
