{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { ... }@inputs:
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
    in
    {
      homeConfigurations = builtins.listToAttrs (inputs.nixpkgs.lib.lists.forEach homes (home: {
        name = "${home.user}@${home.host}";
        value = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
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
          ] ++ inputs.nixpkgs.lib.optionals (home ? config && home.config != null) [
            home.config
          ] ++ inputs.nixpkgs.lib.optionals (home ? type && home.type == "desktop") [
            ./desktop
          ];
        };
      }));
    };
}
