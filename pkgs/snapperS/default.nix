{
  lib,
  stdenv,
  fetchurl,
  python2,
  snapper,
  python3Packages,
}:
let
  version = "1.1.8";
in
stdenv.mkDerivation {
  pname = "snapperS";
  inherit version;
  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/8f/96/24c82ef8988b2af95ac5b458e5cfad819c5ae948cec9960287f67dd95349/snapperS-1.1.8.tar.gz";
    sha256 = "AxuHiseNGvxUzITxU6z9T3t89YPlRRkA+21EO7Pyfi0=";
  };

  buildInputs = [
    python2
    python3Packages.wrapPython
  ];

  pythonPath = [
    (python3Packages.buildPythonPackage (
      let
        pname = "tabulate";
        version = "0.8.10";
      in
      {
        inherit pname version;

        pyproject = true;
        build-system = [ python3Packages.setuptools ];

        src = python3Packages.fetchPypi {
          inherit pname version;
          sha256 = "sha256-bFfz8916wngncBVfOtstsLGiaWN+QvJ1mZJeZLEU9Rk=";
        };

        checkInputs = [ python3Packages.nose ];

        # Tests: cannot import common (relative import).
        doCheck = false;
      }
    ))
  ];

  postPatch = ''
    2to3 snapperS/snapperS
    substituteInPlace snapperS/snapperS --replace "\"snapper " "\"${lib.getBin snapper}/bin/snapper"
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv snapperS/snapperS $out/bin
    wrapPythonPrograms
  '';
}
