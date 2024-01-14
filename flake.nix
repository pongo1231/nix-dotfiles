{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?rev=30e89e4fcdfb4a0e6261cb9a46affd4bfb186862";
      follows = "nixpkgs-unstable";
    };

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-desktop-kernel.url = "github:nixos/nixpkgs?rev=e15a427c7b7e8128403c1c58bb95234d47eb5e36";

    jovian.url = "github:pongo1231/Jovian-NixOS";
    nixpkgs-jupiter-kernel.url = "github:nixos/nixpkgs?rev=c55537aa04e2d5b8de4614b79782d3e5430c3ea7";
    nixpkgs-jupiter-pipewire.url = "github:nixos/nixpkgs?rev=24bacf845b3f08b3a2cf2af32314c51bc7593349";

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    nix-autobahn = {
      url = "github:Lassulus/nix-autobahn";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-be = {
      url = "github:GuilloteauQ/nix-be/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kde2nix = {
      url = "github:nix-community/kde2nix";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , nixpkgs-unstable
    , nixpkgs-desktop-kernel
    , jovian
    , nixpkgs-jupiter-kernel
    , nixpkgs-jupiter-pipewire
    , nix-alien
    , nix-autobahn
    , nix-be
    , kde2nix
    }@inputs: {
      nixosConfigurations =
        let
          commonSystem = { type ? "", hostName, config }: nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };

            modules = [
              ({ ...
               }: {
                nixpkgs.overlays = [
                  (final: prev: {
                    stable = import nixpkgs-stable {
                      inherit system;
                      config = {
                        allowUnfree = true;
                        permittedInsecurePackages = [
                          "python-2.7.18.7"
                        ];
                      };
                    };

                    unstable = import nixpkgs-unstable {
                      inherit system;
                      config.allowUnfree = true;
                    };

                    kernel = import nixpkgs-desktop-kernel {
                      inherit system;
                      config = {
                        allowUnfree = true;
                        nvidia.acceptLicense = true;
                      };
                    };

                    nbfc-linux = final.callPackage ./pkgs/nbfc-linux { };

                    snapperS = final.stable.callPackage ./pkgs/snapperS { };

                    extest = final.pkgsi686Linux.callPackage ./pkgs/extest { };

                    mesa-radv-jupiter = final.callPackage ./pkgs/mesa-radv-jupiter { mesa-radv-jupiter' = prev.mesa-radv-jupiter; };

                    steamPackages = prev.steamPackages.overrideScope (finalScope: prevScope: {
                      steam = prevScope.steam.overrideAttrs (finalAttrs: prevAttrs: {
                        postInstall = prevAttrs.postInstall + ''
                          substituteInPlace $out/share/applications/steam.desktop --replace "steam %U" "LD_PRELOAD=${final.extest}/lib/libextest.so steam %U -silent"
                        '';
                      });
                    });
                  })
                ];

                nixpkgs.config.allowUnfree = true;

                networking = {
                  inherit hostName;
                };
              })

              ./common
            ] ++ nixpkgs.lib.optionals (config != null) [
              config
            ] ++ nixpkgs.lib.optionals (type == "desktop") [
              ./desktop
            ] ++ nixpkgs.lib.optionals (type == "vm") [
              ./vm
            ];
          };
        in
        {
          vm = commonSystem {
            type = "vm";
            hostName = "pongo-vm";
          };

          pongo-nitro5 = commonSystem {
            type = "desktop";
            hostName = "pongo-nitro5";
            config = ./desktop/nitro5;
          };

          pongo-jupiter = commonSystem {
            type = "desktop";
            hostName = "pongo-jupiter";
            config = ./desktop/jupiter;
          };
        };
    };
}
