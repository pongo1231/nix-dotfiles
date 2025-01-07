{ lib
, stdenv
, cmake
, fetchFromGitHub
, suffix ? ""
}:
let
  version = "3a83341da5f75f3df1ec29487377d3c7b9344bd4";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "ksm_preload${suffix}";
  version = builtins.substring 0 6 version;

  src = fetchFromGitHub {
    owner = "pongo1231";
    repo = "ksm_preload";
    rev = version;
    sha256 = "sha256-779H5LZqDeRYs97aX8hb8BcTxAxztCagpD5EQYN0yxQ=";
  };

  nativeBuildInputs = [ cmake ];

  patchPhase = ''
    substituteInPlace ksm-wrapper --replace-fail "readonly KSM_PATH=\$(cd \$(dirname \$0) ; pwd)" "readonly KSM_PATH=$out/share/ksm_preload"
  '';

  postInstall = ''
    mv $out/bin/ksm-wrapper $out/bin/ksm-wrapper${suffix}
  '';
})

