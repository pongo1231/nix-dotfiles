{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
 
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    }@inputs: {
      #home-manager.useGlobalPkgs = true;

      homeConfigurations.pongo = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs; };

        modules = [
          ./home.nix
        ];
      };
    };
}
