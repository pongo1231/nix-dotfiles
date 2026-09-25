{
  lib,
  stdenv,
  python3,
  btrfs-progs,
  gdu,
  makeWrapper,
}:

stdenv.mkDerivation {
  pname = "snapps";
  version = "2.1.0";

  src = ./snapps.py;

  nativeBuildInputs = [
    makeWrapper
    python3
  ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/snapps
    patchShebangs $out/bin/snapps
    wrapProgram $out/bin/snapps --prefix PATH : ${
      lib.makeBinPath [
        btrfs-progs
        gdu
      ]
    }
    runHook postInstall
  '';

  meta = {
    description = "Browse and prune snapper snapshots";
    homepage = "https://github.com/ddworken/snapperS";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    mainProgram = "snapps";
  };
}
