{ lib
, mesa-radv-jupiter'
, fetchFromGitLab
, fetchurl
, fetchpatch
}:

(mesa-radv-jupiter'.overrideAttrs (prevAttrs:
let
  rev = "85849ed9cb6ee802ae6917d8fa78cca86b41fb85";
in
{
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-Jxx53T87i/u56Mk8tobYVX3JJn5o9MUCa0zatYjSwtM=";
  };

  patches = (builtins.filter (x: !lib.strings.hasInfix "000" x /* skip macOS backports */) prevAttrs.patches) ++ [
    ./25352.diff
  ];

  mesonFlags = (builtins.filter (x: !lib.strings.hasInfix "-Dintel-clc" x) prevAttrs.mesonFlags) ++ [
    "-Dintel-clc=system"
    "-Dintel-rt=disabled"
  ];
}))
