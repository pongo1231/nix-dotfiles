# From https://github.com/chayleaf/dotfiles/commit/818ba92987ca5ba53d78bd0159bd4ce1f5965c6b
{
  lib,
  stdenv,
  fetchurl,
  fetchpatch,
  python3Packages,
  zlib,
  pkg-config,
  glib,
  buildPackages,
  perl,
  pixman,
  vde2,
  alsa-lib,
  texinfo,
  flex,
  bison,
  lzo,
  snappy,
  libaio,
  libtasn1,
  gnutls,
  nettle,
  curl,
  ninja,
  meson,
  sigtool,
  makeWrapper,
  removeReferencesTo,
  attr,
  libcap,
  libcap_ng,
  socat,
  libslirp,
  CoreServices,
  Cocoa,
  Hypervisor,
  rez,
  setfile,
  vmnet,
  guestAgentSupport ? with stdenv.hostPlatform; isLinux || isSunOS || isWindows,
  numaSupport ? stdenv.isLinux && !stdenv.isAarch32,
  numactl,
  seccompSupport ? stdenv.isLinux,
  libseccomp,
  alsaSupport ? lib.hasSuffix "linux" stdenv.hostPlatform.system && !nixosTestRunner,
  pulseSupport ? !stdenv.isDarwin && !nixosTestRunner,
  libpulseaudio,
  sdlSupport ? !stdenv.isDarwin && !nixosTestRunner,
  SDL2,
  SDL2_image,
  jackSupport ? !stdenv.isDarwin && !nixosTestRunner,
  libjack2,
  gtkSupport ? !stdenv.isDarwin && !xenSupport && !nixosTestRunner,
  gtk3,
  gettext,
  vte,
  wrapGAppsHook,
  vncSupport ? !nixosTestRunner,
  libjpeg,
  libpng,
  smartcardSupport ? !nixosTestRunner,
  libcacard,
  spiceSupport ? true && !nixosTestRunner,
  spice,
  spice-protocol,
  ncursesSupport ? !nixosTestRunner,
  ncurses,
  usbredirSupport ? spiceSupport,
  usbredir,
  xenSupport ? false,
  xen,
  cephSupport ? false,
  ceph,
  glusterfsSupport ? false,
  glusterfs,
  libuuid,
  openGLSupport ? sdlSupport,
  mesa,
  libepoxy,
  libdrm,
  virglSupport ? openGLSupport,
  virglrenderer,
  libiscsiSupport ? true,
  libiscsi,
  smbdSupport ? false,
  samba,
  tpmSupport ? true,
  uringSupport ? stdenv.isLinux,
  liburing,
  canokeySupport ? false,
  canokey-qemu,
  hostCpuOnly ? false,
  hostCpuTargets ? (
    if hostCpuOnly then
      (lib.optional stdenv.isx86_64 "i386-softmmu" ++ [ "${stdenv.hostPlatform.qemuArch}-softmmu" ])
    else
      null
  ),
  nixosTestRunner ? false,
  doCheck ? false,
  qemu, # for passthru.tests
  enableDocs ? true,
}:

stdenv.mkDerivation rec {
  pname =
    "qemu"
    + lib.optionalString xenSupport "-xen"
    + lib.optionalString hostCpuOnly "-host-cpu-only"
    + lib.optionalString nixosTestRunner "-for-vm-tests";
  version = "7.2.3";

  src = fetchurl {
    url = "https://download.qemu.org/qemu-${version}.tar.xz";
    hash = "sha256-Wak5qNYTiCap8oIysta1/ohJRuLddiW7jAdFKGxrddk=";
  };

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  nativeBuildInputs = [
    makeWrapper
    removeReferencesTo
    pkg-config
    flex
    bison
    meson
    ninja
    perl

    # Don't change this to python3 and python3.pkgs.*, breaks cross-compilation
    python3Packages.python
    python3Packages.sphinx
    python3Packages.sphinx-rtd-theme
  ]
  ++ lib.optionals gtkSupport [ wrapGAppsHook ]
  ++ lib.optionals stdenv.isDarwin [ sigtool ];

  buildInputs = [
    zlib
    glib
    perl
    pixman
    vde2
    texinfo
    lzo
    snappy
    libtasn1
    gnutls
    nettle
    curl
    libslirp
  ]
  ++ lib.optionals ncursesSupport [ ncurses ]
  ++ lib.optionals stdenv.isDarwin [
    CoreServices
    Cocoa
    Hypervisor
    rez
    setfile
    vmnet
  ]
  ++ lib.optionals seccompSupport [ libseccomp ]
  ++ lib.optionals numaSupport [ numactl ]
  ++ lib.optionals alsaSupport [ alsa-lib ]
  ++ lib.optionals pulseSupport [ libpulseaudio ]
  ++ lib.optionals sdlSupport [
    SDL2
    SDL2_image
  ]
  ++ lib.optionals jackSupport [ libjack2 ]
  ++ lib.optionals gtkSupport [
    gtk3
    gettext
    vte
  ]
  ++ lib.optionals vncSupport [
    libjpeg
    libpng
  ]
  ++ lib.optionals smartcardSupport [ libcacard ]
  ++ lib.optionals spiceSupport [
    spice-protocol
    spice
  ]
  ++ lib.optionals usbredirSupport [ usbredir ]
  ++ lib.optionals stdenv.isLinux [
    libaio
    libcap_ng
    libcap
    attr
  ]
  ++ lib.optionals xenSupport [ xen ]
  ++ lib.optionals cephSupport [ ceph ]
  ++ lib.optionals glusterfsSupport [
    glusterfs
    libuuid
  ]
  ++ lib.optionals openGLSupport [
    mesa
    libepoxy
    libdrm
  ]
  ++ lib.optionals virglSupport [ virglrenderer ]
  ++ lib.optionals libiscsiSupport [ libiscsi ]
  ++ lib.optionals smbdSupport [ samba ]
  ++ lib.optionals uringSupport [ liburing ]
  ++ lib.optionals canokeySupport [ canokey-qemu ];

  dontUseMesonConfigure = true; # meson's configurePhase isn't compatible with qemu build

  outputs = [ "out" ] ++ lib.optional guestAgentSupport "ga";
  # On aarch64-linux we would shoot over the Hydra's 2G output limit.
  separateDebugInfo = !(stdenv.isAarch64 && stdenv.isLinux);

  patches = [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/b51530a54883e994adbbf64e11afe7b359541c8b/pkgs/applications/virtualization/qemu/fix-qemu-ga.patch";
      sha256 = "sha256-vPuyWlw8o6fkr1tG1jTyDuyAB7o5fW50Iisr3GjuQY8=";
    })

    # QEMU upstream does not demand compatibility to pre-10.13, so 9p-darwin
    # support on nix requires utimensat fallback. The patch adding this fallback
    # set was removed during the process of upstreaming this functionality, and
    # will still be needed in nix until the macOS SDK reaches 10.13+.
    (fetchpatch {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/b51530a54883e994adbbf64e11afe7b359541c8b/pkgs/applications/virtualization/qemu/provide-fallback-for-utimensat.patch";
      sha256 = "sha256-HekG/9vK6igvwhND+T8Klhj/42SW1KUlBxb9p/vsdYM=";
    })
    # Cocoa clipboard support only works on macOS 10.14+
    (fetchpatch {
      url = "https://raw.githubusercontent.com/NixOS/nixpkgs/b51530a54883e994adbbf64e11afe7b359541c8b/pkgs/applications/virtualization/qemu/revert-ui-cocoa-add-clipboard-support.patch";
      sha256 = "sha256-EEjGDbJ91UkeBD5MCzjLYKAMdgWiP8J+uJOf9EBrxfk=";
    })
    # Standard about panel requires AppKit and macOS 10.13+
    (fetchpatch {
      url = "https://gitlab.com/qemu-project/qemu/-/commit/99eb313ddbbcf73c1adcdadceba1423b691c6d05.diff";
      sha256 = "sha256-gTRf9XENAfbFB3asYCXnw4OV4Af6VE1W56K2xpYDhgM=";
      revert = true;
    })
    # Workaround for upstream issue with nested virtualisation: https://gitlab.com/qemu-project/qemu/-/issues/1008
    (fetchpatch {
      url = "https://gitlab.com/qemu-project/qemu/-/commit/3e4546d5bd38a1e98d4bd2de48631abf0398a3a2.diff";
      sha256 = "sha256-oC+bRjEHixv1QEFO9XAm4HHOwoiT+NkhknKGPydnZ5E=";
      revert = true;
    })
    # glibc >=2.37 compat, see https://lore.kernel.org/qemu-devel/20230110174901.2580297-1-berrange@redhat.com/
    (fetchpatch {
      url = "https://gitlab.com/qemu-project/qemu/-/commit/9f0246539ae84a5e21efd1cc4516fc343f08115a.patch";
      sha256 = "sha256-1iWOWkLH0WP1Hk23fmrRVdX7YZWUXOvWRMTt8QM93BI=";
    })
    (fetchpatch {
      url = "https://gitlab.com/qemu-project/qemu/-/commit/6003159ce18faad4e1bc7bf9c85669019cd4950e.patch";
      sha256 = "sha256-DKGCbR+VDIFLp6FhER78gyJ3Rn1dD47pMtkcIIMd0B8=";
    })
  ]
  ++ lib.optional nixosTestRunner (fetchpatch {
    url = "https://raw.githubusercontent.com/NixOS/nixpkgs/b51530a54883e994adbbf64e11afe7b359541c8b/pkgs/applications/virtualization/qemu/force-uid0-on-9p.patch";
    sha256 = "sha256-26XFSKO7JJ+jwRZrsb9zSZdUVZICwCtg0qny51eU0D4=";
  });

  postPatch = ''
    # Otherwise tries to ensure /var/run exists.
    sed -i "/install_emptydir(get_option('localstatedir') \/ 'run')/d" \
        qga/meson.build
  '';

  preConfigure = ''
    unset CPP # intereferes with dependency calculation
    # this script isn't marked as executable b/c it's indirectly used by meson. Needed to patch its shebang
    chmod +x ./scripts/shaderinclude.py
    patchShebangs .
    # avoid conflicts with libc++ include for <version>
    mv VERSION QEMU_VERSION
    substituteInPlace configure \
      --replace '$source_path/VERSION' '$source_path/QEMU_VERSION'
    substituteInPlace meson.build \
      --replace "'VERSION'" "'QEMU_VERSION'"
  '';

  configureFlags = [
    "--disable-strip" # We'll strip ourselves after separating debug info.
    "--enable-tools"
    "--localstatedir=/var"
    "--sysconfdir=/etc"
    # Always use our Meson, not the bundled version, which doesn't
    # have our patches and will be subtly broken because of that.
    "--meson=meson"
    "--cross-prefix=${stdenv.cc.targetPrefix}"
    (lib.enableFeature guestAgentSupport "guest-agent")
  ]
  ++ lib.optional enableDocs "--enable-docs"
  ++ lib.optional numaSupport "--enable-numa"
  ++ lib.optional seccompSupport "--enable-seccomp"
  ++ lib.optional smartcardSupport "--enable-smartcard"
  ++ lib.optional spiceSupport "--enable-spice"
  ++ lib.optional usbredirSupport "--enable-usb-redir"
  ++ lib.optional (hostCpuTargets != null) "--target-list=${lib.concatStringsSep "," hostCpuTargets}"
  ++ lib.optionals stdenv.isDarwin [
    "--enable-cocoa"
    "--enable-hvf"
  ]
  ++ lib.optional stdenv.isLinux "--enable-linux-aio"
  ++ lib.optional gtkSupport "--enable-gtk"
  ++ lib.optional xenSupport "--enable-xen"
  ++ lib.optional cephSupport "--enable-rbd"
  ++ lib.optional glusterfsSupport "--enable-glusterfs"
  ++ lib.optional openGLSupport "--enable-opengl"
  ++ lib.optional virglSupport "--enable-virglrenderer"
  ++ lib.optional tpmSupport "--enable-tpm"
  ++ lib.optional libiscsiSupport "--enable-libiscsi"
  ++ lib.optional smbdSupport "--smbd=${samba}/bin/smbd"
  ++ lib.optional uringSupport "--enable-linux-io-uring"
  ++ lib.optional canokeySupport "--enable-canokey";

  dontWrapGApps = true;

  # QEMU attaches entitlements with codesign and strip removes those,
  # voiding the entitlements and making it non-operational.
  # The alternative is to re-sign with entitlements after stripping:
  # * https://github.com/qemu/qemu/blob/v6.1.0/scripts/entitlement.sh#L25
  dontStrip = stdenv.isDarwin;

  postFixup = ''
    # the .desktop is both invalid and pointless
    rm -f $out/share/applications/qemu.desktop
  ''
  + lib.optionalString guestAgentSupport ''
    # move qemu-ga (guest agent) to separate output
    mkdir -p $ga/bin
    mv $out/bin/qemu-ga $ga/bin/
    ln -s $ga/bin/qemu-ga $out/bin
    remove-references-to -t $out $ga/bin/qemu-ga
  ''
  + lib.optionalString gtkSupport ''
    # wrap GTK Binaries
    for f in $out/bin/qemu-system-*; do
      wrapGApp $f
    done
  '';
  preBuild = "cd build";

  # tests can still timeout on slower systems
  inherit doCheck;
  nativeCheckInputs = [ socat ];
  preCheck = ''
    # time limits are a little meagre for a build machine that's
    # potentially under load.
    substituteInPlace ../tests/unit/meson.build \
      --replace 'timeout: slow_tests' 'timeout: 50 * slow_tests'
    substituteInPlace ../tests/qtest/meson.build \
      --replace 'timeout: slow_qtests' 'timeout: 50 * slow_qtests'
    substituteInPlace ../tests/fp/meson.build \
      --replace 'timeout: 90)' 'timeout: 300)'

    # point tests towards correct binaries
    substituteInPlace ../tests/unit/test-qga.c \
      --replace '/bin/echo' "$(type -P echo)"
    substituteInPlace ../tests/unit/test-io-channel-command.c \
      --replace '/bin/socat' "$(type -P socat)"

    # combined with a long package name, some temp socket paths
    # can end up exceeding max socket name len
    substituteInPlace ../tests/qtest/bios-tables-test.c \
      --replace 'qemu-test_acpi_%s_tcg_%s' '%s_%s'

    # get-fsinfo attempts to access block devices, disallowed by sandbox
    sed -i -e '/\/qga\/get-fsinfo/d' -e '/\/qga\/blacklist/d' \
      ../tests/unit/test-qga.c
  ''
  + lib.optionalString stdenv.isDarwin ''
    # skip test that stalls on darwin, perhaps due to subtle differences
    # in fifo behaviour
    substituteInPlace ../tests/unit/meson.build \
      --replace "'test-io-channel-command'" "#'test-io-channel-command'"
  '';

  # Add a ‘qemu-kvm’ wrapper for compatibility/convenience.
  postInstall = ''
    ln -s $out/bin/qemu-system-${stdenv.hostPlatform.qemuArch} $out/bin/qemu-kvm
  ''
  + lib.optionalString stdenv.isLinux ''
    ln -s $out/libexec/virtiofsd $out/bin
  '';

  passthru = {
    qemu-system-i386 = "bin/qemu-system-i386";
    tests = {
      qemu-tests = qemu.override { doCheck = true; };
    };
  };

  # Builds in ~3h with 2 cores, and ~20m with a big-parallel builder.
  requiredSystemFeatures = [ "big-parallel" ];

  meta = with lib; {
    homepage = "http://www.qemu.org/";
    description = "A generic and open source machine emulator and virtualizer";
    license = licenses.gpl2Plus;
    mainProgram = "qemu-kvm";
    maintainers = with maintainers; [
      eelco
      qyliss
    ];
    platforms = platforms.unix;
    priority = 10; # Prefer virtiofsd from the virtiofsd package.
  };
}
