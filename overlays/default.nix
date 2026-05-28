{
  inputs,
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

  nbfc-linux = prev.nbfc-linux.overrideAttrs (prevAttrs: {
    src = final.fetchFromGitHub {
      owner = "nbfc-linux";
      repo = "nbfc-linux";
      rev = "92b4cc7881e252aa847cd82cfeffadc4e8c8291a";
      hash = "sha256-bOgUMcdJbNlqqjjyHeQSbgrOZ7HmfI6wka24ies5ysA=";
    };
    patches = (prevAttrs.patches or [ ]) ++ [ (patch /nbfc-linux/170.patch) ];
    buildInputs = (prevAttrs.buildInputs or [ ]) ++ [ final.python3 ];
    configureFlags = [
      "--prefix=${placeholder "out"}"
      "--sysconfdir=${placeholder "out"}/etc"
      "--bindir=${placeholder "out"}/bin"
    ];
    postPatch = ''
      substituteInPlace src/nbfc.h --replace-fail 'SYSCONFDIR "/nbfc"' '"/etc/nbfc"'
      substituteInPlace src/nbfc.h --replace-fail 'SYSCONFDIR "/nbfc/nbfc.json"' '"/etc/nbfc/nbfc.json"'
    '';
  });

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

  duperemove = prev.duperemove.overrideAttrs {
    src = final.fetchFromGitHub {
      owner = "markfasheh";
      repo = "duperemove";
      rev = "897a222e731cc9dccc7ae4d6065034b561201c5c";
      hash = "sha256-/MkbR2lOxC/3kXrHqkkL7ngvCILutJpScNxfIx+CdDU=";
    };

    patches = (prev.patches or [ ]) ++ [
      (patch /duperemove/slop.patch)
    ];
  };

  ryzenadj = prev.ryzenadj.overrideAttrs {
    src = final.fetchFromGitHub {
      owner = "FlyGoat";
      repo = "RyzenAdj";
      rev = "7aeb2f4869ee52ac161ee4cb4871e29113487885";
      hash = "sha256-KE2dbGv4V3+ibyxJ/DHNnBOGzjAcZbGrC3cVGNDsTTQ=";
    };
  };

  snapperS = final.callPackage (pkg /snapperS) { };

  mosh = prev.mosh.overrideAttrs (prevAttrs: {
    postPatch = (prevAttrs.postPatch or "") + ''
      substituteInPlace src/frontend/stmclient.h --replace-fail "if ( predict_mode )" "if ( false )"
      substituteInPlace src/frontend/terminaloverlay.h --replace-fail "display_preference( Adaptive )" "display_preference( Experimental )"
    '';
  });

  bottles = inputs.nixpkgs2.legacyPackages.${final.stdenv.hostPlatform.system}.bottles.override {
    removeWarningPopup = true;
  };

  reasonix = final.callPackage (pkg /reasonix) { };
}
