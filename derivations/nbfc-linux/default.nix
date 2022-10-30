{ lib
, stdenv
, fetchFromGitHub
, makeWrapper
, python3
, kmod
, # for modprobe
}:
let
  version = "0.1.7";
in
stdenv.mkDerivation {
  pname = "nbfc-linux";
  inherit version;

  src = fetchFromGitHub {
    owner = "nbfc-linux";
    repo = "nbfc-linux";
    rev = version;
    sha256 = "Q/W/O2cevofDNzn2ly1r6mfl39VnSrYxocKLr+JxQ3s=";
  };

  nativeBuildInputs = [ makeWrapper ];
  installFlags = [ "DESTDIR=\${out}" ];

  postPatch = ''
    substituteInPlace nbfc.py.in --replace "/usr/bin/python3" "/usr/bin/env python3"
    substituteInPlace nbfc.py.in --replace "@CONFDIR@" "/etc"
    substituteInPlace nbfc.py.in --replace "nbfc_service -f%s" "$out/bin/nbfc_service -f%s"

    substituteInPlace src/nbfc.h --replace "CONFDIR \"" "\"/etc"
    substituteInPlace src/nbfc.h --replace "DATADIR \"" "\"/$out/share"
  '';

  postInstall = ''
    mkdir $out/bin
    mv $out/usr/local/bin/* $out/bin

    mkdir $out/share
    mv $out/usr/local/share/* $out/share

    wrapProgram $out/bin/nbfc --prefix PATH : ${lib.makeBinPath [python3 kmod]}
    #wrapProgram $out/usr/bin/nbfc_service --prefix PATH
  '';
}
