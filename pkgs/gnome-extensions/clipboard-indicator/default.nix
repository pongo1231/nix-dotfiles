{
  gnomeExtensions,
  fetchzip,
}:
# extensions.gnome.org upload 74 is the first one that declares GNOME 51; the
# nixpkgs pin still ships upload 71, whose metadata stops at 50.
#
# The source is fetched directly instead of going through the nixpkgs builder's
# `metadata` substitution, so the archive's own metadata.json (with the 51
# entry) is installed unchanged.
(gnomeExtensions.clipboard-indicator.overrideAttrs (prev: {
  version = "74";

  src = fetchzip {
    url = "https://extensions.gnome.org/extension-data/clipboard-indicatortudmotu.com.v74.shell-extension.zip";
    sha256 = "sha256-mdhWlN4ATRZvw6Kmr10x956nOJANwD+kttM2qajTWUU=";
    stripRoot = false;
  };
}))
