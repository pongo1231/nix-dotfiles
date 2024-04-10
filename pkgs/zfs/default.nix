{ zfs
, fetchFromGitHub
, configFile
, kernel ? null
, removeLinuxDRM ? true
}:

(zfs.override (prevAttrs: { inherit configFile kernel removeLinuxDRM; })).overrideAttrs (finalAttrs: prevAttrs:
let
  rev = "d98973dbdd5a85b6c8a8556d5bd5c9903e2d2ee6";
in
{
  name = builtins.replaceStrings [ prevAttrs.version ] [ finalAttrs.version ] prevAttrs.name;
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitHub {
    owner = "openzfs";
    repo = "zfs";
    inherit rev;
    hash = "sha256-Dt/MRIjqqiJOFwpkfoJPO23Eu+CrkIg2RaIUfIa9AHk=";
  };

  meta = prevAttrs.meta // { broken = false; };
})
