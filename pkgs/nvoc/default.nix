{ lib
, stdenv
, fetchFromGitHub
, nvidia_x11
, makeWrapper
}:
let
  version = "1.0.3";
in
stdenv.mkDerivation {
  pname = "nvoc";
  inherit version;
  src = fetchFromGitHub {
    owner = "yavincl";
    repo = "nvoc";
    rev = version;
    sha256 = "P3hFx6o/g1dnePMsubhVEb7zNw1qX71vfw76E17y3hU=";
  };

  nativeBuildInputs = [ makeWrapper ];

  postPatch = ''
    patchShebangs nvoc
    # substituteInPlace ./nvoc --replace /etc/nvoc.d $out/etc/nvoc.d
  '';

  installPhase = ''
    mkdir -p $out/bin/ $out/etc/
    mv nvoc $out/bin/
    # mv gpu0.conf $out/etc/

    wrapProgram $out/bin/nvoc --prefix PATH : ${lib.makeBinPath [nvidia_x11 nvidia_x11.settings]}
  '';
}
