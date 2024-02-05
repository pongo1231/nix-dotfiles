{ mesa-radv-jupiter'
, fetchFromGitLab
, fetchurl
}:

mesa-radv-jupiter'.overrideAttrs (prevAttrs:
let
  rev = "5178ad761c9e8e86ffb3bc59322ec998c0ae2063";
in
{
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-JcNXhSsjC3oI5efOkDHG4P9BVshFIajoui8EaoAYr7M=";
  };

  patches = prevAttrs.patches ++ [ ./25352.diff ];
})
