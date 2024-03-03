{ lib
, mesa-radv-jupiter'
, fetchFromGitLab
, fetchurl
, fetchpatch
}:

(mesa-radv-jupiter'.overrideAttrs (prevAttrs:
let
  rev = "7ba43413b92cd671929f1722030db344ee8bc120";
in
{
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-Tn3SPRDZU4l0qG2p3oPe10E0RZr+J6AgoP6kneMfwTg=";
  };

  patches = (builtins.filter (x: !lib.strings.hasInfix "000" x /* skip macOS backports */) prevAttrs.patches) ++ [
    ./25352.diff
  ];

  mesonFlags = (builtins.filter (x: !lib.strings.hasInfix "-Dintel-clc" x) prevAttrs.mesonFlags) ++ [
    "-Dintel-clc=system"
    "-Dintel-rt=disabled"
  ];
}))
