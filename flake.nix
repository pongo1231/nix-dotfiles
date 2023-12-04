{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?rev=30e89e4fcdfb4a0e6261cb9a46affd4bfb186862";
      follows = "nixpkgs-unstable";
    };

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-kernel = {
      url = "github:nixos/nixpkgs?rev=30e89e4fcdfb4a0e6261cb9a46affd4bfb186862";
      #follows = "nixpkgs";
    };

    nixpkgs-jupiter-kernel.url = "github:nixos/nixpkgs?rev=1ba227e3333a83ee7d5d8cb03d00308e6c991ce8";
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
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , nixpkgs-unstable
    , nixpkgs-kernel
    , nixpkgs-jupiter-kernel
    , nixpkgs-jupiter-pipewire
    , nix-alien
    , nix-autobahn
    , nix-be
    }@inputs: {
      nixosConfigurations =
        let
          commonSystem = { type ? "", hostName, imports ? [ ] }: nixpkgs.lib.nixosSystem rec {
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

                    kernel = import nixpkgs-kernel {
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

                    steamPackages = prev.steamPackages.overrideScope (scopeFinal: scopePrev: {
                      steam = scopePrev.steam.overrideAttrs (finalAttrs: prevAttrs: {
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
            ] ++ imports
            ++ nixpkgs.lib.optionals (type == "desktop") [
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
            imports = [ ./desktop/nitro5 ];
          };

          pongo-jupiter = commonSystem {
            type = "desktop";
            hostName = "pongo-jupiter";
            imports = [ ./desktop/jupiter ];
          };
        };
    };
}
