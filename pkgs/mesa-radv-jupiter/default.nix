{ lib
, mesa-radv-jupiter'
, fetchFromGitLab
, fetchurl
, fetchpatch
}:

(mesa-radv-jupiter'.overrideAttrs (prevAttrs:
let
  rev = "cc74a819e41c0275e5e4cbf93931d7554b05f665";
in
{
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-jzJ+w+ny5e9ONtSDKYCvKmf4yQQ9dJ1ECsNSgtD7dTs=";
  };

  patches = (builtins.filter (x: !lib.strings.hasInfix "000" x /* skip macOS backports */) prevAttrs.patches) ++ [
    ./25352.diff
  ];

  mesonFlags = (builtins.filter (x: !lib.strings.hasInfix "-Dintel-clc" x) prevAttrs.mesonFlags) ++ [
    "-Dintel-clc=system"
    "-Dintel-rt=disabled"
  ];
}))
