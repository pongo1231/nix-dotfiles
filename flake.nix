{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nur.url = "github:nix-community/NUR";
  };

  outputs = {
    self,
    nixpkgs,
    nur,
    ...
  } @ inputs:
    with inputs; {
      nixosConfigurations = {
        pongo-nixos = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";

          specialArgs = inputs;
          modules = [
            nur.nixosModules.nur

            ({
              config,
              pkgs,
              ...
            }: {
              nixpkgs.overlays = [
                (final: prev: {
                  nbfc-linux = final.callPackage ./derivations/nbfc-linux {};
                  nvoc = final.callPackage ./derivations/nvoc {nvidia_x11 = pkgs.linuxPackages.nvidia_x11;};

                  #config.hardware.xpadneo.extraModulePackages = [xpadneo];
                })
              ];

              disabledModules = ["hardware/video/nvidia.nix"];
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
