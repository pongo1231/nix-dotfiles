{
  lib,
  stdenv,
  suffix ? "",
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "ksm_wrap${suffix}";
  version = "1.0";

  src = ./.;

  buildPhase = ''
    ${stdenv.cc}/bin/gcc main.c -shared
  '';

  installPhase = ''
    mkdir -p $out/bin/
    mv a.out $out/bin/ksmwrap${suffix}.so
  '';
})
