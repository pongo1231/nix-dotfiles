{
  kernel,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "hp-omen-linux-module";
  version = "rebase-6.12";

  src = fetchFromGitHub {
    owner = "ranisalt";
    repo = "hp-omen-linux-module";
    rev = finalAttrs.version;
    sha256 = "sha256-EfOjKSgLbOysctaR+X7DJR2SdfAcUi4R/cXhVHrEw4M=";
  };

  setSourceRoot = ''
    export sourceRoot=$(pwd)/${finalAttrs.src.name}/src
  '';

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    #"TARGET=${kernel.modDirVersion}"
    "KERNELDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    #"-C"
    #"${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    #"M=$(sourceRoot)"
    #"VERSION=${finalAttrs.version}"
  ];

  installPhase = ''
    runHook preInstall

    install hp-wmi.ko -Dm444 -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/platform/x86/hp/

    runHook postInstall
  '';

  #buildFlags = [ "modules" ];
  #installFlags = [ "INSTALL_MOD_PATH=${placeholder "out"}" ];
  #installTargets = [ "modules_install" ];
})
