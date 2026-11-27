{
  zfs,
  fetchFromGitHub,
  configFile,
  kernel ? null,
  removeLinuxDRM ? true,
}:

(zfs.override {
  inherit configFile kernel removeLinuxDRM;
}).overrideAttrs
  (
    final: prev:
    let
      rev = "3b6d727ddd8d6d005774605964f044f364ee6456";
    in
    {
      name = builtins.replaceStrings [ prev.version ] [ final.version ] prev.name;
      version = "git-${builtins.substring 0 6 rev}";

      src = fetchFromGitHub {
        owner = "openzfs";
        repo = "zfs";
        inherit rev;
        hash = "sha256-lGy5eCR7MsSopKsmWEdhlY5xg/zH6pT2sdmkQRV+rQ0=";
      };

      meta = prev.meta // {
        broken = false;
      };
    }
  )
