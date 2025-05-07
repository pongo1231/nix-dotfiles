{
  stdenv,
  fetchFromGitHub,
  makeWrapper,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "udp-reverse-tunnel";
  version = "1.3";

  src = fetchFromGitHub {
    owner = "prof7bit";
    repo = finalAttrs.pname;
    rev = "24c9c3a9c5d8dadf2a8ea97cef7c2b8bb4846b28";
    hash = "sha256-pQlcKbMKRTozkaRpic5bmnw5TACszbG4zN3mqzMjV20=";
  };

  nativeBuildInputs = [ makeWrapper ];

  makeFlags = [ "prefix=${placeholder "out"}" ];

  preInstall = ''
    mkdir -p $out/bin/
  '';
})
