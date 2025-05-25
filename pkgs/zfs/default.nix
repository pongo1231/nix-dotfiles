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
      rev = "645b83307918085ab2f0e12618809e348635b34f";
    in
    {
      name = builtins.replaceStrings [ prev.version ] [ final.version ] prev.name;
      version = "git-${builtins.substring 0 6 rev}";

      src = fetchFromGitHub {
        owner = "openzfs";
        repo = "zfs";
        inherit rev;
        hash = "sha256-hVATgJt9uvRiifphzzHfW3oCjqxz4O3yFujV4YMXEUA=";
      };

      meta = prev.meta // {
        broken = false;
      };
    }
  )
