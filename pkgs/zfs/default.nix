{ zfs
, fetchFromGitHub
, configFile
, kernel ? null
, removeLinuxDRM ? true
}:

(zfs.override (prevAttrs: { inherit configFile kernel removeLinuxDRM; })).overrideAttrs (finalAttrs: prevAttrs:
let
  rev = "b28461b7c6511be571ee2f7d71c0d7be12aa4630";
in
{
  name = builtins.replaceStrings [ prevAttrs.version ] [ finalAttrs.version ] prevAttrs.name;
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitHub {
    owner = "openzfs";
    repo = "zfs";
    inherit rev;
    hash = "sha256-umpuAvQlHV1//0tDkE8C1uDiCtbJADGoVu/KDbxtaW4=";
  };

  meta = prevAttrs.meta // { broken = false; };
})
