{
  lib,
  stdenv,
  fetchurl,
  kernel,
  kernelModuleMakeFlags,
}:

let
  KDIR = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";

  # ADIOS 3.3.0r2, as published by upstream for Linux 7.3-rc1. Only its
  # block/adios.c is used here; the patch's remaining hunks exist to make ADIOS
  # the built-in default scheduler (and to tweak setlocalversion), which is
  # exactly what building it out of tree avoids.
  adiosPatch = fetchurl {
    url = "https://raw.githubusercontent.com/firelzrd/adios/6fa79e32d9a33a0d671b108074aca2b5df9cd967/patches/stable/0001-linux7.3-rc1-ADIOS-3.3.0r2.patch";
    hash = "sha256-TxhvoGv7Dg4IMgy1Ojiv6+bZ6qXIIDlgFcWfmTv44bY=";
  };

  # Extract the `block/adios.c` part of the patch (1986 lines, matching the
  # patch's own hunk header) so the scheduler source is never vendored here.
  extractAdios = ''
    awk '/^diff --git a\/block\/adios\.c/{f=1;next} /^diff --git /{f=0;h=0} f&&/^@@/{h=1;next} f&&h&&/^\+/{sub(/^\+/,"");print}' \
      ${adiosPatch} > adios.c
    test "$(wc -l < adios.c)" -eq 1986
  '';
in
stdenv.mkDerivation {
  pname = "adios-iosched";
  version = "3.3.0r2-${kernel.version}";

  src = ./.;

  postPatch = extractAdios;

  makeFlags = kernelModuleMakeFlags ++ [ "KDIR=${KDIR}" ];

  # Install via kbuild so the module lands where boot.extraModulePackages expects
  # it and is compressed with the kernel's own options (scripts/Makefile.modinst
  # uses --check=crc32 --lzma2=dict=1MiB; the in-kernel xz decoder accepts no
  # other check type, so hand-rolling `xz` here silently produces a module the
  # kernel refuses to decompress).
  installPhase = ''
    runHook preInstall

    make -C ${KDIR} M=$PWD INSTALL_MOD_PATH="$out" modules_install

    runHook postInstall
  '';

  meta = {
    description = "Adaptive Deadline I/O scheduler (ADIOS) as an out-of-tree blk-mq elevator";
    homepage = "https://github.com/firelzrd/adios";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
  };
}
