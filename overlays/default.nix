{
  patch,
  pkg,
}:
final: prev:
let
  inherit (prev) lib;
in
{
  linuxPackages_latest = prev.linuxPackages_latest.extend (
    final': prev': {
      opensnitch-ebpf = prev'.opensnitch-ebpf.overrideAttrs (prev'': {
        preBuild = prev''.preBuild or "" + ''
          makeFlagsArray+=(EXTRA_FLAGS="-Wno-microsoft-anon-tag -fms-extensions")
        '';
      });
    }
  );

  ksmwrap64 = final.callPackage (pkg /ksmwrap) { suffix = "64"; };
  ksmwrap32 = final.pkgsi686Linux.callPackage (pkg /ksmwrap) { suffix = "32"; };
  ksmwrap = final.writeShellScriptBin "ksmwrap" ''
    exec env LD_PRELOAD=$LD_PRELOAD:${final.ksmwrap64}/bin/ksmwrap64.so${
      lib.optionalString (
        final.stdenv.hostPlatform.system == "x86_64-linux"
      ) ":${final.ksmwrap32}/bin/ksmwrap32.so"
    } "$@"
  '';

  udp-reverse-tunnel = final.callPackage (pkg /udp-reverse-tunnel) { };

  duperemove = prev.duperemove.overrideAttrs (prevAttrs: {
    src = final.fetchFromGitHub {
      owner = "markfasheh";
      repo = "duperemove";
      rev = "897a222e731cc9dccc7ae4d6065034b561201c5c";
      hash = "sha256-/MkbR2lOxC/3kXrHqkkL7ngvCILutJpScNxfIx+CdDU=";
    };

    patches = (prevAttrs.patches or [ ]) ++ [
      (patch /duperemove/slop.patch)
    ];
  });

  snapps = final.callPackage (pkg /snapps) { };

  mosh = prev.mosh.overrideAttrs (prevAttrs: {
    postPatch = (prevAttrs.postPatch or "") + ''
      substituteInPlace src/frontend/stmclient.h --replace-fail "if ( predict_mode )" "if ( false )"
      substituteInPlace src/frontend/terminaloverlay.h --replace-fail "display_preference( Adaptive )" "display_preference( Experimental )"
    '';
  });

  bottles = prev.bottles.override {
    removeWarningPopup = true;
  };

  reasonix = final.callPackage (pkg /reasonix) { };

  distrobox = final.callPackage (pkg /distrobox) { };

  lsfg-vk = prev.lsfg-vk.overrideAttrs (prevAttrs: {
    src = final.fetchFromGitHub {
      owner = "PancakeTAS";
      repo = "lsfg-vk";
      rev = "218820e8dc2d69c21a7a0775b5c47f2c447ed31a";
      hash = "sha256-Qb3vufCzNpM1r+vgo8M9nnA7CENgGTithWG0oXqLKbI=";
      fetchSubmodules = true;
    };

    patches = (prevAttrs.patches or [ ]) ++ [ (patch /lsfg-vk/slop.patch) ];
    postPatch = "";

    postInstall = ''
      substituteInPlace "$out/share/vulkan/implicit_layer.d/VkLayer_LSFGVK_frame_generation.json" \
        --replace-fail "liblsfg-vk-layer.so" "$out/lib/liblsfg-vk-layer.so"
    '';

    nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [
      final.qt6.wrapQtAppsHook
    ];

    buildInputs = prevAttrs.buildInputs ++ [
      final.qt6.qtbase
      final.qt6.qtdeclarative
    ];

    cmakeFlags = [
      (lib.cmakeFeature "LSFGVK_BUILD_UI" "ON")
    ];
  });

  /*
    kdePackages = prev.kdePackages.overrideScope (
      kfinal: kprev: {
        kwin = kprev.kwin.overrideAttrs (prevAttrs: {
          patches = (prevAttrs.patches or [ ]) ++ [ (patch /kwin/lazy-render-device.patch) ];
        });
      }
    );
  */

  swapspace = prev.swapspace.overrideAttrs (prev: {
    patches = (prev.patches or [ ]) ++ [ (patch /swapspace/slop.patch) ];
  });
}
