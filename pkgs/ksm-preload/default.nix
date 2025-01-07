{ lib
, stdenv
, cmake
, fetchFromGitHub
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
})
