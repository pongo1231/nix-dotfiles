{ lib
, mesa-radv-jupiter'
, fetchFromGitLab
}:

(mesa-radv-jupiter'.overrideAttrs (prevAttrs:
let
  rev = "1a475c70b26680b48dfddc3893397c44c8886583";
in
{
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-ytSCxfoCldTZ86VBRnykHWRvwcV9ZWKC77ObkMpuPPM=";
  };

  patches = (builtins.filter (x: !lib.strings.hasInfix "000" x /* skip macOS backports */) prevAttrs.patches) ++ [
    ./25352.diff
  ];

  mesonFlags = (builtins.filter (x: !lib.strings.hasInfix "-Dintel-clc" x) prevAttrs.mesonFlags) ++ [
    "-Dintel-clc=system"
    "-Dintel-rt=disabled"
  ];
}))
