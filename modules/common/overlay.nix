{
  system,
  configInfo,
  patch,
  pkg,
  lib,
  ...
}:
lib.optionalAttrs (configInfo.type == "host" || !configInfo.isNixosModule) {
  /*
    # https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=system.replaceDependencies
    system.replaceDependencies.replacements = [

    ];

    # https://github.com/hsjobeki/nixpkgs/blob/migrate-doc-comments/pkgs/build-support/replace-dependencies.nix#L35:C1
    pkgs.replaceDependencies = [

    ]
  */

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
        version = "git";
        src = final.fetchFromGitHub {
          owner = "89luca89";
          repo = "distrobox";
          rev = "9e9192409af3d442884d676db7c5214b34f1afdc";
          hash = "sha256-1VPTybGtP3EqrNFZthJM8nwHRHpUfL29/lwJIBNZ/U8=";
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
