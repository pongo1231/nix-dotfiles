{ stdenv
, fetchFromGitHub
, kernel
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "hp-omen-linux-module";
  version = "rebase-6.12";

  src = fetchFromGitHub {
    owner = "pongo1231";
    repo = "hp-omen-linux-module";
    rev = finalAttrs.version;
    sha256 = "sha256-NwtObMqezlU+yJL65dxUbhdfzUEtJkytwkx7lfraEZ0=";
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
