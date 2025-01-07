{ lib
, multiStdenv
, suffix ? ""
, is32Bit ? false
}:
multiStdenv.mkDerivation (finalAttrs: {
  pname = "ksm_preload${suffix}";
  version = "main";

  src = ./.;

  buildPhase = ''
    ${multiStdenv.cc}/bin/gcc main.c -shared ${lib.optionalString is32Bit "-m32"}
  '';

  installPhase = ''
    mkdir -p $out/bin/
    mv a.out $out/bin/ksm-wrapper${suffix}
  '';
})

