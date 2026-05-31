{
  lib,
  stdenv,
  fetchurl,
  go,
}:
let
  src = fetchurl {
    url = "https://github.com/esengine/DeepSeek-Reasonix/archive/fa0a75f3fcfc64422b7872379faf8c52568b6106.tar.gz";
    hash = "sha256-YcfWHiljXPU2UAYEtYwW6awfVDqIlpQtLmzSMOH9RPI=";
  };

  vendor = stdenv.mkDerivation {
    name = "reasonix-vendor";
    inherit src;

    nativeBuildInputs = [ go ];

    outputHash = "sha256-As/FStEPaBn/opFJjg0Bclq8vy/unZGdNZJKmaR4p2A=";
    outputHashMode = "recursive";

    buildPhase = ''
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
