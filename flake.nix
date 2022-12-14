{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-ld.url = "github:Mic92/nix-ld/main";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , nur
    , nix-alien
    , nix-ld
    }@inputs: {
      nixosConfigurations = {
        pongo-nixos = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };

          modules = [
            #nur.nixosModules.nur

            ({ self
             , config
             , lib
             , specialArgs
             , options
             , modulesPath
             , pkgs
             , libsForQt5
             , inputs
             }: {
              nixpkgs.overlays = [
                (final: prev: {
                  unstable = inputs.nixpkgs-unstable.legacyPackages.${system}.pkgs;

                  nbfc-linux = final.callPackage ./derivations/nbfc-linux { };
                  #nvoc = final.callPackage ./derivations/nvoc { nvidia_x11 = pkgs.linuxPackages.nvidia_x11; };
                  krunner-translator = final.libsForQt5.callPackage ./derivations/krunner-translator { };
                  snapperS = final.callPackage ./derivations/snapperS { };

                  #config.hardware.xpadneo.extraModulePackages = [xpadneo];
                })
              ];

              #disabledModules = [ "hardware/video/nvidia.nix" ];
              #imports = [
              #  ./derivations/nvidia.nix
              #];
            })

            ./derivations/nbfc-linux/service.nix
            #./derivations/nvoc/service.nix

            ./configuration.nix
          ];
        };
      };
    };
}
