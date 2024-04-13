{ zfs
, fetchFromGitHub
, configFile
, kernel ? null
, removeLinuxDRM ? true
}:

(zfs.override (prevAttrs: { inherit configFile kernel removeLinuxDRM; })).overrideAttrs (finalAttrs: prevAttrs:
let
  rev = "b181b2e604de3f36feab1092c702cdec5e78c693";
in
{
  name = builtins.replaceStrings [ prevAttrs.version ] [ finalAttrs.version ] prevAttrs.name;
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitHub {
    owner = "openzfs";
    repo = "zfs";
    inherit rev;
    hash = "sha256-e3MFZR1Mx2Z51e0ZE5DmL01KWVctyht2HVycu8MGVSY=";
  };

  meta = prevAttrs.meta // { broken = false; };
})
