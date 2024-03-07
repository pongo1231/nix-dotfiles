{ lib
, mesa-radv-jupiter'
, fetchFromGitLab
, fetchurl
, fetchpatch
}:

(mesa-radv-jupiter'.overrideAttrs (prevAttrs:
let
  rev = "a6f270c1601e37d04b0b05d54e3be67525126ad9";
in
{
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-IS8Ym4TRjuA6TW9+U1+iAhrbmKh/VAQfR8H9czYohbc=";
  };

  patches = (builtins.filter (x: !lib.strings.hasInfix "000" x /* skip macOS backports */) prevAttrs.patches) ++ [
    ./25352.diff
  ];

  mesonFlags = (builtins.filter (x: !lib.strings.hasInfix "-Dintel-clc" x) prevAttrs.mesonFlags) ++ [
    "-Dintel-clc=system"
    "-Dintel-rt=disabled"
  ];
}))
