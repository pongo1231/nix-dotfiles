{ lib
, stdenv
, fetchFromGitHub
, kernel
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "hp-omen-linux-module";
  version = "rebase-6.9";

  src = fetchFromGitHub {
    owner = "ranisalt";
    repo = "hp-omen-linux-module";
    rev = "290748430a57eb7046bd5f5a0f858c33bcea444f";
    sha256 = "sha256-a5ndrr4ueYUsMLjJmcv830qLIY4+sGB+21D0JSclczA=";
  };

  setSourceRoot = ''
    export sourceRoot=$(pwd)/${finalAttrs.src.name}/src
  '';

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernel.makeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(sourceRoot)"
    "VERSION=${finalAttrs.version}"
  ];

  buildFlags = [ "modules" ];
  installFlags = [ "INSTALL_MOD_PATH=${placeholder "out"}" ];
  installTargets = [ "modules_install" ];
})
