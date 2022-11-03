{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";

    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-ld.url = "github:Mic92/nix-ld/main";
  };

  outputs =
    { self
    , nixpkgs
    , nur
    , nix-alien
    , nix-ld
    , ...
    }: {
      nixosConfigurations = {
        pongo-nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit self; };

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
             }: {
              nixpkgs.overlays = [
                (final: prev: {
                  nbfc-linux = final.callPackage ./derivations/nbfc-linux { };
                  nvoc = final.callPackage ./derivations/nvoc { nvidia_x11 = pkgs.linuxPackages.nvidia_x11; };
                  krunner-translator = final.libsForQt5.callPackage ./derivations/krunner-translator { };

                  #config.hardware.xpadneo.extraModulePackages = [xpadneo];
                })
              ];

              disabledModules = [ "hardware/video/nvidia.nix" ];
              imports = [
                ./derivations/nvidia.nix
              ];
            })

            ./derivations/nbfc-linux/service.nix
            ./derivations/nvoc/service.nix

            ./configuration.nix
          ];
        };
      };
    };
}
