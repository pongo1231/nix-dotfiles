{
  kernel,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation (final: {
  pname = "hp-omen-linux-module";
  version = "rebase-6.15";

  src = fetchFromGitHub {
    owner = "ranisalt";
    repo = "hp-omen-linux-module";
    rev = final.version;
    sha256 = "sha256-IOXHzcCB0n1InMjeIu3XYEJ4bhbHS3NIlS8/+4XIwkQ=";
  };

  setSourceRoot = ''
    export sourceRoot=$(pwd)/${final.src.name}/src
  '';

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KERNELDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installPhase = ''
    runHook preInstall

    install hp-wmi.ko -Dm444 -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/platform/x86/hp/

    runHook postInstall
  '';
})
