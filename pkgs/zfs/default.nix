{ zfs
, fetchFromGitHub
, removeLinuxDRM ? true
}:

(zfs.override (prevAttrs: { inherit removeLinuxDRM; })).overrideAttrs (finalAttrs: prevAttrs:
let
  rev = "a5a725440bcb2f4c4554be3e489f911e3dd60412";
in
{
  name = builtins.replaceStrings [ prevAttrs.version ] [ finalAttrs.version ] prevAttrs.name;
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitHub {
    owner = "openzfs";
    repo = "zfs";
    inherit rev;
    hash = "sha256-D6OO9hkb/qSSEojkjdzJwAAxp4fvvZvz6D/wt94GZAY=";
  };

  meta = prevAttrs.meta // { broken = false; };
}
)
