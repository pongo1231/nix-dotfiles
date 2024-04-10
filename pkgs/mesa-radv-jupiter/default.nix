{ lib
, mesa-radv-jupiter'
, wayland-protocols
, fetchurl
, fetchFromGitLab
}:

mesa-radv-jupiter'.overrideAttrs (prevAttrs:
let
  rev = "1f4662cc4ed0c5b87479eb71e53a1320ab1b414b";
in
{
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-Kg5swJ/dpk0V2tYVUU++SAtlIJ2tgYbWWfM9nmjKYL4=";
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
