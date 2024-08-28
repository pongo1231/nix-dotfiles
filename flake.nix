{
  inputs = {
    nixpkgs.url = "github:pongo1231/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:pongo1231/nixpkgs/797f7dc49e0bc7fab4b57c021cdf68f595e47841";

    nixpkgs-desktop-kernel = {
      #url = "github:nixos/nixpkgs/7cadc175919016d329c868915f1f1c42fc8fb817";
      follows = "nixpkgs";
    };

    jovian = {
      url = "github:pongo1231/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-jupiter-kernel.url = "github:nixos/nixpkgs/ac63aa91609080ea542349b6f958e512196b8ba5";

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

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic = {
      url = "github:pongo1231/nyx";
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

                      #mesa-radv-jupiter = final.callPackage ./pkgs/mesa-radv-jupiter { mesa-radv-jupiter' = prev.mesa-radv-jupiter; };

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

                      duperemove = prev.duperemove.overrideAttrs (finalAttrs: prevAttrs: {
                        src = final.fetchFromGitHub {
                          owner = "markfasheh";
                          repo = "duperemove";
                          rev = "131bee3fda7112fdbe4419f24485022eff1815f3";
                          hash = "sha256-h6TZGST+jaqsKOf/CRQ3cJQAWoyHS+v0Fniw+PoB5dI=";
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

                inputs.lix-module.nixosModules.default

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
