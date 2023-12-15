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
    }@inputs:
    let
      homes = [
        {
          user = "pongo";
          host = "pongo-nitro5";
          type = "desktop";
          config = ./desktop/nitro5;
        }
        {
          user = "pongo";
          host = "pongo-jupiter";
          type = "desktop";
        }
      ];
      mkHomes = homes: builtins.listToAttrs (nixpkgs.lib.lists.forEach homes (home: {
        name = "${home.user}@${home.host}";
        value = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs; };

          modules = [
            ({ ...
             }: {
              nixpkgs.overlays = [
                (final: prev: {
                  # ...
                })
              ];

              home = {
                username = home.user;
                homeDirectory = "/home/${home.user}";
              };
            })

            ./common
          ] ++ nixpkgs.lib.optionals (home.config != null) [
            home.config
          ] ++ nixpkgs.lib.optionals (home ? type && home.type == "desktop") [
            ./desktop
          ];
        };
      }));
    in
    {
      homeConfigurations = mkHomes homes;
    };
}
