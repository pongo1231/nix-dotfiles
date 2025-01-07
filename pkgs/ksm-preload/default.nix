{ lib
, stdenv
, cmake
, fetchFromGitHub
, is32Bit ? false
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "ksm_preload";
  version = "0.11";

  src = fetchFromGitHub {
    owner = "unbrice";
    repo = finalAttrs.pname;
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-Bc6ChHF9EtDb5c0pYBtyy3O4fkIfkKh9Bm5pX/skfqE=";
  };

  nativeBuildInputs = [ cmake ];

  patchPhase = ''
    substituteInPlace ksm-wrapper --replace-fail "readonly KSM_PATH=\$(cd \$(dirname \$0) ; pwd)" "readonly KSM_PATH=$out/share/ksm_preload"
  '';

  postInstall = lib.optionals is32Bit ''
    mv $out/bin/ksm-wrapper $out/bin/ksm-wrapper32
  '';
})
