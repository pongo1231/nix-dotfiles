{ lib
, mesa-radv-jupiter'
, wayland-protocols
, fetchurl
, fetchFromGitLab
}:

mesa-radv-jupiter'.overrideAttrs (prevAttrs:
let
  rev = "04f232ed99bb68ef7c5169173253d4cdfa840bce";
in
{
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-NDnaL3RHOqKYGBeOWWtl3l1+RZBdLnr7eu0/DpZFLME=";
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
