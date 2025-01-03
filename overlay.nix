{ inputs
, system
}:
(final: prev: {
  kernel = import inputs.nixpkgs-desktop-kernel {
    inherit system;
    config = {
      allowUnfree = true;
      nvidia.acceptLicense = true;
    };
  };

  nbfc-linux = final.callPackage ./pkgs/nbfc-linux { };

  extest = final.pkgsi686Linux.callPackage ./pkgs/extest { };

  #mesa-radv-jupiter = final.callPackage ./pkgs/mesa-radv-jupiter { mesa-radv-jupiter' = prev.mesa-radv-jupiter; };

  steamPackages = prev.steamPackages.overrideScope (finalScope: prevScope: {
    steam = prevScope.steam.overrideAttrs (finalAttrs: prevAttrs: {
      postInstall = prevAttrs.postInstall + ''
        substituteInPlace $out/share/applications/steam.desktop --replace "steam %U" "LD_PRELOAD=${final.extest}/lib/libextest.so steam %U -silent"
      '';
    });
  });

  libvirt = prev.libvirt.override (prevAttrs: { enableXen = false; });

  openvswitch = prev.openvswitch.override { kernel = null; };

  virtiofsd = final.callPackage ./pkgs/qemu_7/virtiofsd.nix {
    qemu = final.callPackage ./pkgs/qemu_7 {
      inherit (final.darwin.apple_sdk.frameworks) CoreServices Cocoa Hypervisor vmnet;
      inherit (final.darwin.stubs) rez setfile;
      inherit (final.darwin) sigtool;
    };
  };

  distrobox = prev.distrobox.overrideAttrs (finalAttrs: prevAttrs: {
    version = "git";
    src = final.fetchFromGitHub {
      owner = "89luca89";
      repo = "distrobox";
      rev = "3bac964bf0952674848dce170af8b41d743abe57";
      hash = "sha256-uPCnI52PjxZPPzoMqS3ayF+5lqvQqb8WmeP1BxAC2ZE=";
    };
  });

  decky-loader = inputs.nixpkgs-stable.legacyPackages.${system}.callPackage "${inputs.jovian}/pkgs/decky-loader" { };
  /*decky-loader = prev.decky-loader.overridePythonAttrs (prevAttrs: {
    dependencies = (builtins.filter (x: x != inputs.nixpkgs.legacyPackages.${system}.python3Packages.watchdog) prevAttrs.dependencies) ++ [
      inputs.nixpkgs-stable.legacyPackages.${system}.python3Packages.watchdog
    ];
  });*/
})
