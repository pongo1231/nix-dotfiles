{ lib
, mesa-radv-jupiter'
, fetchFromGitLab
}:

(mesa-radv-jupiter'.overrideAttrs (prevAttrs:
let
  rev = "58e3b1f930feb70f3294180847aa758f0e76fb26";
in
{
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-FI9STWe8OzjQAu43SxLZPdELSNIDbremQ5DJikr7vqg=";
  };

  patches = (builtins.filter (x: !lib.strings.hasInfix "000" x /* skip macOS backports */) prevAttrs.patches) ++ [
    ./25352.diff
  ];

  mesonFlags = (builtins.filter (x: !lib.strings.hasInfix "-Dintel-clc" x) prevAttrs.mesonFlags) ++ [
    "-Dintel-clc=system"
    "-Dintel-rt=disabled"
  ];
}))
