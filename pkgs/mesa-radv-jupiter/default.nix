{ lib
, mesa-radv-jupiter'
, wayland-protocols
, fetchurl
, fetchFromGitLab
}:

mesa-radv-jupiter'.overrideAttrs (prevAttrs:
let
  rev = "fe36cf6cad9b226dff993a8f1f8f0bf451f095c5";
in
{
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-ppaH8bI6CMGuW8NvU773Yx7yJCsNyB+An8MlDM3GQkA=";
  };

  patches = (builtins.filter (x: !lib.strings.hasInfix "000" x /* skip macOS backports */) prevAttrs.patches) ++ [
    ./25352.diff
  ];

  mesonFlags = (builtins.filter (x: !lib.strings.hasInfix "-Dintel-clc" x) prevAttrs.mesonFlags) ++ [
    "-Dintel-clc=system"
    "-Dintel-rt=disabled"
  ];

  buildInputs = (builtins.filter (x: x.pname != "wayland-protocols") prevAttrs.buildInputs) ++ [
    (wayland-protocols.overrideAttrs (finalAttrs: prevAttrs: {
      version = "1.34";

      src = fetchurl {
        url = "https://gitlab.freedesktop.org/wayland/${finalAttrs.pname}/-/releases/${finalAttrs.version}/downloads/${finalAttrs.pname}-${finalAttrs.version}.tar.xz";
        hash = "sha256-xZsnys2F9guvTuX4DfXA0Vdg6taiQysAq34uBXTcr+s=";
      };
    }))
  ];
})
