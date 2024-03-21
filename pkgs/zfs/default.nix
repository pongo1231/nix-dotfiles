{ zfs
, fetchFromGitHub
, configFile
, kernel ? null
, removeLinuxDRM ? true
}:

(zfs.override (prevAttrs: { inherit configFile kernel removeLinuxDRM; })).overrideAttrs (finalAttrs: prevAttrs:
let
  rev = "c9d8f6c59a268f65075bb9e510a58b1eec8015f7";
in
{
  name = builtins.replaceStrings [ prevAttrs.version ] [ finalAttrs.version ] prevAttrs.name;
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitHub {
    owner = "openzfs";
    repo = "zfs";
    inherit rev;
    hash = "sha256-cvdcnrJijUWjySbNeFSPIYIMg8ptxwNV7wmuWnf8IXo=";
  };

  meta = prevAttrs.meta // { broken = false; };
})
