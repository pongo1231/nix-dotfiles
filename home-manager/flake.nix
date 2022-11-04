{
  inputs = {
    home-manager.url = "github:nix-community/home-manager";
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
