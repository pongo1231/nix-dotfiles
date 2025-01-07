{ lib
, multiStdenv
, suffix ? ""
, is32Bit ? false
}:
multiStdenv.mkDerivation (finalAttrs: {
  pname = "ksm_wrap${suffix}";
  version = "1.0";

  src = ./.;

  buildPhase = ''
    ${multiStdenv.cc}/bin/gcc main.c -shared ${lib.optionalString is32Bit "-m32"}
  '';

  installPhase = ''
    mkdir -p $out/bin/
    mv a.out $out/bin/ksmwrap${suffix}
  '';
})

