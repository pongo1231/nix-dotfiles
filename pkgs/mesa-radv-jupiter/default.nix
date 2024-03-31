{ lib
, mesa-radv-jupiter'
, fetchFromGitLab
}:

(mesa-radv-jupiter'.overrideAttrs (prevAttrs:
let
  rev = "96ee0d6711ed162b2d3545d7f70927ed35d20c91";
in
{
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-iVLvEaTpBMDse6VX24F5CGgz2t/8GTd3z49LFZULZqs=";
  };

  patches = (builtins.filter (x: !lib.strings.hasInfix "000" x /* skip macOS backports */) prevAttrs.patches) ++ [
    ./25352.diff
  ];

  mesonFlags = (builtins.filter (x: !lib.strings.hasInfix "-Dintel-clc" x) prevAttrs.mesonFlags) ++ [
    "-Dintel-clc=system"
    "-Dintel-rt=disabled"
  ];
}))
