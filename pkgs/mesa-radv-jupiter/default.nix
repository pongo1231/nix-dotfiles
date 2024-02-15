{ lib
, mesa-radv-jupiter'
, fetchFromGitLab
, fetchurl
, fetchpatch
}:

((mesa-radv-jupiter'.override (prevAttrs: {
  
})).overrideAttrs (prevAttrs:
let
  rev = "90eae30bcb84d54dc871ddbb8355f729cf8fa900";
in
{
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-EJihKqmLHJmIgRpKx5lTTDlFoT5jCEFLQlJYTYifJLY=";
  };

  patches = (builtins.filter (x: !lib.strings.hasInfix "000" x /* skip macOS backports */) prevAttrs.patches) ++ [
    ./25352.diff
  ];

  mesonFlags = (builtins.filter (x: !lib.strings.hasInfix "-Dintel-clc" x) prevAttrs.mesonFlags) ++ [
    "-Dintel-clc=system"
  ];
}))
