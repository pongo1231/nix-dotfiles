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

      /*
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
      */

      distrobox = prev.distrobox.overrideAttrs {
        version = "1.9-git";
        src = final.fetchFromGitHub {
          owner = "89luca89";
          repo = "distrobox";
          rev = "c530defaa384f76fdfa09cb94931d364f98218d1";
          hash = "sha256-tMxGYX5SIcqNPK5a9HqY6dMsMdMF4NxtRiScoW+YKBA=";
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
          rev = "897a222e731cc9dccc7ae4d6065034b561201c5c";
          hash = "sha256-/MkbR2lOxC/3kXrHqkkL7ngvCILutJpScNxfIx+CdDU=";
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
