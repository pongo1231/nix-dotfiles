{
  lib,
  mesa-radv-jupiter',
  wayland-protocols,
  fetchurl,
  fetchFromGitLab,
}:

mesa-radv-jupiter'.overrideAttrs (
  prev:
  let
    rev = "6ab4b2d7a063c525dc98c80f272643bc47f41f96";
  in
  {
    version = "git-${builtins.substring 0 6 rev}";

    src = fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "Mesa";
      repo = "mesa";
      inherit rev;
      hash = "sha256-jtPdnPREPPuy8qSQCCqnGHo46n1EvCc5FyXnZpI4ioI=";
    };

    patches =
      (builtins.filter (
        x: !lib.strings.hasInfix "000" x # skip macOS backports
      ) prev.patches)
      ++ [
        ./25352.diff
      ];

    mesonFlags = (builtins.filter (x: !lib.strings.hasInfix "-Dintel-clc" x) prev.mesonFlags) ++ [
      "-Dintel-clc=system"
      "-Dintel-rt=disabled"
    ];

    buildInputs = (builtins.filter (x: x.pname != "wayland-protocols") prev.buildInputs) ++ [
      (wayland-protocols.overrideAttrs (final: {
        version = "1.34";

        src = fetchurl {
          url = "https://gitlab.freedesktop.org/wayland/${final.pname}/-/releases/${final.version}/downloads/${final.pname}-${final.version}.tar.xz";
          hash = "sha256-xZsnys2F9guvTuX4DfXA0Vdg6taiQysAq34uBXTcr+s=";
        };
      }))
    ];
  }
)
