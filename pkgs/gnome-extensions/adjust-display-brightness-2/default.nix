{
  lib,
  stdenv,
  fetchzip,
  glib,
  patch,
}:
stdenv.mkDerivation {
  pname = "gnome-shell-extension-adjust-display-brightness-2";
  version = "9";

  src = fetchzip {
    url = "https://gitlab.com/bruno.englert/gnome-extension-brightness/-/archive/63e7aa7d14b26532b81c63b470d38c745e0e7d4d/gnome-extension-brightness-63e7aa7d14b26532b81c63b470d38c745e0e7d4d.tar.gz";
    hash = "sha256-/FHPjKCf3FSwcwUJ8JFyz8vPPrjYNy/ZiKld3VcdMBI=";
  };

  patches = [
    (patch /brightness2/local-changes.patch)
  ];

  patchFlags = [
    "-p1"
    "--fuzz=0"
  ];

  nativeBuildInputs = [ glib ];

  buildPhase = ''
    runHook preBuild
    glib-compile-schemas --strict src/schemas
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    dir=$out/share/gnome-shell/extensions/gnome-extension-brightness2@bruno.englert.gitlab.com
    mkdir -p "$dir"
    cp -r src/. "$dir"
    cp LICENSE "$dir"
    runHook postInstall
  '';

  meta = {
    description = "Control external monitor brightness via DDC/CI, with software dimming for displays without backlight control";
    platforms = lib.platforms.linux;
  };

  passthru.extensionUuid = "gnome-extension-brightness2@bruno.englert.gitlab.com";
}
