{ zfs
, fetchFromGitHub
, removeLinuxDRM ? true
}:

(zfs.override (prevAttrs: { inherit removeLinuxDRM; })).overrideAttrs (finalAttrs: prevAttrs:
let
  rev = "e0bd8118d04b55b7adf3d9ba256ad4bb53e66512";
in
{
  name = builtins.replaceStrings [ prevAttrs.version ] [ finalAttrs.version ] prevAttrs.name;
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitHub {
    owner = "openzfs";
    repo = "zfs";
    inherit rev;
    hash = "sha256-y3E7xnanIX3XihygtdXJJvL5TtegxBF5MhZ1hltbfMs=";
  };

  meta = prevAttrs.meta // { broken = false; };
})
