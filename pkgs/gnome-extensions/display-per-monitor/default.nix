{
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "gnome-shell-extension-display-per-monitor";
  version = "1.0";

  src = ./src;

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions/display-per-monitor@local
    cp -r . $out/share/gnome-shell/extensions/display-per-monitor@local
    runHook postInstall
  '';

  meta = {
    description = "Re-applies each monitor's own display settings when the set of connected monitors changes";
    platforms = lib.platforms.linux;
  };

  passthru.extensionUuid = "display-per-monitor@local";
}
