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

      extest = final.pkgsi686Linux.callPackage (pkg /extest) { };

      steamPackages = prev.steamPackages.overrideScope (prevScope: {
        steam = prevScope.steam.overrideAttrs (prevAttrs: {
          postInstall =
            prevAttrs.postInstall
            + ''
              substituteInPlace $out/share/applications/steam.desktop --replace "steam %U" "LD_PRELOAD=${final.extest}/lib/libextest.so steam %U -silent"
            '';
        });
      });

      libvirt = prev.libvirt.override {
        enableXen = false;
      };

      openvswitch = prev.openvswitch.override { kernel = null; };

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
    })
  ];
}
