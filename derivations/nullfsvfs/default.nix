{ lib
, stdenv
, fetchFromGitHub
, kernel
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "nullfsvfs";
  version = "0.14";

  src = fetchFromGitHub {
    owner = "abbbi";
    repo = "nullfsvfs";
    rev = "refs/tags/v${finalAttrs.version}";
    sha256 = "sha256-Dp2o/Rq77yY68DfCW2xeQC+5W54jywnfril2J8yquQc=";
  };

  setSourceRoot = ''
    export sourceRoot=$(pwd)/source
  '';

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernel.makeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(sourceRoot)"
    "INSTALL_MOD_DIR=kernel/fs/nullfs"
  ];

  patchPhase = ''
    runHook prePatch
    substituteInPlace ./Makefile --replace "/lib/modules/$(shell uname -r)/build" "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    substituteInPlace ./Makefile --replace "M=$(shell pwd)" "M=$(pwd)/source"
    substituteInPlace ./Makefile --replace " modules" ""
    runHook postPatch
  '';

  installFlags = [ "INSTALL_MOD_PATH=${placeholder "out"}" ];
  installTargets = [ "modules_install" ];
})
