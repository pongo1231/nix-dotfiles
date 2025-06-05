{
  system,
  configInfo,
  patch,
  pkg,
  lib,
  ...
}:
lib.optionalAttrs (configInfo.type == "host" || !configInfo.isNixosModule) {
  nixpkgs.overlays = [
    (final: prev: {
      nbfc-linux = prev.nbfc-linux.overrideAttrs (prev: {
        src = final.fetchFromGitHub {
          owner = "nbfc-linux";
          repo = "nbfc-linux";
          rev = "92b4cc7881e252aa847cd82cfeffadc4e8c8291a";
          hash = "sha256-bOgUMcdJbNlqqjjyHeQSbgrOZ7HmfI6wka24ies5ysA=";
        };
        patches = (prev.patches or [ ]) ++ [ (patch /nbfc-linux/170.patch) ];
        buildInputs = (prev.buildInputs or [ ]) ++ [ final.python3 ];
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

      virtiofsd = final.callPackage (pkg /qemu_7/virtiofsd.nix) {
        qemu = final.callPackage (pkg /qemu_7) {
          inherit (final.darwin.apple_sdk.frameworks)
            CoreServices
            Cocoa
            Hypervisor
            vmnet
            ;
          inherit (final.darwin.stubs) rez setfile;
          inherit (final.darwin) sigtool;
        };
      };

      distrobox = prev.distrobox.overrideAttrs {
        version = "1.8.1.2";
        src = final.fetchFromGitHub {
          owner = "89luca89";
          repo = "distrobox";
          rev = "3b9f0e8d3d8bd102e1636a22afffafe00777d30b";
          hash = "sha256-wTu+8SQZaf8TKkjyvKqTvIWnCZTiPnozybTu5uKXEJk=";
        };
      };

      ksmwrap64 = final.callPackage (pkg /ksmwrap) { suffix = "64"; };
      ksmwrap32 = final.pkgsi686Linux.callPackage (pkg /ksmwrap) { suffix = "32"; };
      ksmwrap = final.writeShellScriptBin "ksmwrap" ''
        exec env LD_PRELOAD=$LD_PRELOAD:${final.ksmwrap64}/bin/ksmwrap64.so${
          lib.optionalString (system == "x86_64-linux") ":${final.ksmwrap32}/bin/ksmwrap32.so"
        } "$@"
      '';

      udp-reverse-tunnel = final.callPackage (pkg /udp-reverse-tunnel) { };

      duperemove = prev.duperemove.overrideAttrs {
        src = final.fetchFromGitHub {
          owner = "markfasheh";
          repo = "duperemove";
          rev = "f0efb090c9c0eb5214b5eed8a0189b089e24965d";
          hash = "sha256-Y3HIqq61bLfZi4XR2RtSyuCPmcWrTxeWvqpTh+3hUjc=";
        };
      };

      nix-tree = prev.nix-tree.overrideAttrs {
        src = final.fetchFromGitHub {
          owner = "utdemir";
          repo = "nix-tree";
          rev = "fdcac72b7261f32e2faf9866c5d759d38a19771a";
          hash = "sha256-XDtt664UxDiZoIHm+i+v2Tib/zpCGBKilrZET29mBwI=";
        };
      };

      ryzenadj = prev.ryzenadj.overrideAttrs {
        src = final.fetchFromGitHub {
          owner = "FlyGoat";
          repo = "RyzenAdj";
          rev = "7aeb2f4869ee52ac161ee4cb4871e29113487885";
          hash = "sha256-KE2dbGv4V3+ibyxJ/DHNnBOGzjAcZbGrC3cVGNDsTTQ=";
        };
      };
    })
  ];
}
