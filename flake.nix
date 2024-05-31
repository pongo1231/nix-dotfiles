{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    nixpkgs-desktop-kernel = {
      #url = "github:nixos/nixpkgs?rev=7cadc175919016d329c868915f1f1c42fc8fb817";
      follows = "nixpkgs";
    };

    jovian = {
      url = "github:pongo1231/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-jupiter-kernel.url = "github:nixos/nixpkgs?rev=0d3377a696f110f746142176c4c5d79b2c1f7028";

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-autobahn = {
      url = "github:Lassulus/nix-autobahn";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-be = {
      url = "github:GuilloteauQ/nix-be/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { ... }@inputs: {
      nixosConfigurations =
        let
          commonSystem = { type ? null, hostName, config ? null }:
            let
              system = "x86_64-linux";
            in
            inputs.nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs = { inherit inputs; };

              modules = [
                ({ ...
                 }: {
                  nixpkgs.overlays = [
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

                      mesa-radv-jupiter = final.callPackage ./pkgs/mesa-radv-jupiter { mesa-radv-jupiter' = prev.mesa-radv-jupiter; };

                      steamPackages = prev.steamPackages.overrideScope (finalScope: prevScope: {
                        steam = prevScope.steam.overrideAttrs (finalAttrs: prevAttrs: {
                          postInstall = prevAttrs.postInstall + ''
                            substituteInPlace $out/share/applications/steam.desktop --replace "steam %U" "LD_PRELOAD=${final.extest}/lib/libextest.so steam %U -silent"
                          '';
                        });
                      });

                      distrobox = prev.distrobox.overrideAttrs (finalAttrs: prevAttrs: {
                        version = "1.7.2.1";
                        src = final.fetchFromGitHub {
                          owner = "89luca89";
                          repo = "distrobox";
                          rev = finalAttrs.version;
                          hash = "sha256-H2jeKs0h4ZAcP33HB5jptlubq62cwnjPK2wSlEIfFWA=";
                        };
                      });

                      virtiofsd = final.callPackage ./pkgs/qemu_7/virtiofsd.nix {
                        qemu = (final.callPackage ./pkgs/qemu_7 {
                          inherit (final.darwin.apple_sdk.frameworks) CoreServices Cocoa Hypervisor vmnet;
                          inherit (final.darwin.stubs) rez setfile;
                          inherit (final.darwin) sigtool;
                        });
                      };
                    })
                  ];

                  nixpkgs.config.allowUnfree = true;

                  networking = {
                    inherit hostName;
                  };
                })

                ./common
              ] ++ inputs.nixpkgs.lib.optionals (config != null) [
                config
              ] ++ inputs.nixpkgs.lib.optionals (type == "desktop") [
                ./desktop
              ] ++ inputs.nixpkgs.lib.optionals (type == "vm") [
                ./vm
              ];
            };
        in
        inputs.nixpkgs.lib.concatMapAttrs
          (name: value:
            let
              hostName = inputs.nixpkgs.lib.removeSuffix ".nix" name;
            in
            {
              ${hostName} = commonSystem ((import ./systems/${name}) // { inherit hostName; });
            })
          (builtins.readDir ./systems);
    };
}
