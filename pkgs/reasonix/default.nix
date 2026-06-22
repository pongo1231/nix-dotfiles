{
  lib,
  stdenv,
  fetchurl,
  go,
}:
let
  src = fetchurl {
    url = "https://github.com/esengine/DeepSeek-Reasonix/archive/051239b633604195c8449f13df31024dee7d3cc9.tar.gz";
    hash = "sha256-WTcDCglrJB9j/Z/qKOsai0ZnX0pKYzlmd3vCf9wl5cQ=";
  };

  vendor = stdenv.mkDerivation {
    name = "reasonix-vendor";
    inherit src;

    nativeBuildInputs = [ go ];

    outputHash = "sha256-YEI500JHH6+6mHkGrXpcQVEKJiKJinL1lpR7vBv4xg4=";
    outputHashMode = "recursive";

    buildPhase = ''
      export GOTOOLCHAIN=local
      export GOPATH=$TMPDIR/go
      export GOMODCACHE=$TMPDIR/go/pkg/mod
      export GOCACHE=$TMPDIR/go/cache
      go mod vendor
    '';

    installPhase = ''
      mkdir -p $out
      cp -r vendor $out/
    '';
  };
in
stdenv.mkDerivation {
  pname = "reasonix";
  version = "git";

  inherit src;

  nativeBuildInputs = [ go ];

  configurePhase = ''
    cp -r ${vendor}/vendor ./vendor
    chmod -R u+w ./vendor
  '';

  buildPhase = ''
    export GOTOOLCHAIN=local
    export GOPATH=$TMPDIR/go
    export GOMODCACHE=$TMPDIR/go/pkg/mod
    export GOCACHE=$TMPDIR/go/cache
    CGO_ENABLED=0 go build -mod=vendor -ldflags "-s -w" -o bin/reasonix ./cmd/reasonix
    CGO_ENABLED=0 go build -mod=vendor -ldflags "-s -w" -o bin/reasonix-plugin-example ./cmd/reasonix-plugin-example
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp bin/reasonix $out/bin/
    cp bin/reasonix-plugin-example $out/bin/
  '';

  meta = with lib; {
    description = "DeepSeek-native AI coding agent for your terminal";
    homepage = "https://github.com/esengine/DeepSeek-Reasonix";
    license = licenses.mit;
    mainProgram = "reasonix";
  };
}
