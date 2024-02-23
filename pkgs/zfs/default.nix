{ zfs
, fetchFromGitHub
, configFile
, kernel ? null
, removeLinuxDRM ? true
}:

(zfs.override (prevAttrs: { inherit configFile kernel removeLinuxDRM; })).overrideAttrs (finalAttrs: prevAttrs:
let
  rev = "af4da5ccf28e1de6d4f6771a8d9d7cc578aba087";
in
{
  name = builtins.replaceStrings [ prevAttrs.version ] [ finalAttrs.version ] prevAttrs.name;
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitHub {
    owner = "openzfs";
    repo = "zfs";
    inherit rev;
    hash = "sha256-9SdDDIUAR3joSwjFkr2LFnoe9qb/7DpiW3376w9JGeI=";
  };

  meta = prevAttrs.meta // { broken = false; };
})
