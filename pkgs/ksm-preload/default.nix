{ lib
, stdenv
, cmake
, fetchFromGitHub
, suffix ? ""
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "ksm_preload${suffix}";
  version = "main";

  src = ./.;

  buildPhase = ''
    ${stdenv.cc}/bin/gcc main.c -shared
  '';

  installPhase = ''
    ls
    mkdir -p $out/bin/
    mv a.out $out/bin/ksm-wrapper${suffix}
  '';
})

