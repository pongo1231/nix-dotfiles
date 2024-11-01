{
  inputs = {
    nixpkgs.url = "github:pongo1231/nixpkgs/mine";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { ... }@inputs:
    let
      commonConfig = { info, user, config ? null, userConfig ? null }: inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.${if info ? system && info.system != null then info.system else "x86_64-linux"};
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
              username = user;
              homeDirectory = "/home/${user}";
            };
          })

          ./modules/common
        ] ++ inputs.nixpkgs.lib.optionals (info ? type && (info.type == "graphical" || info.type == "desktop")) [
          ./modules/graphical
        ] ++ inputs.nixpkgs.lib.optionals (info ? type && info.type == "desktop") [
          ./modules/desktop
        ] ++ inputs.nixpkgs.lib.optionals (config != null) [
          config
        ] ++ inputs.nixpkgs.lib.optionals (userConfig != null) [
          userConfig
        ];
      };
    in
    {
      homeConfigurations = inputs.nixpkgs.lib.foldlAttrs
        (acc: hostName: _:
          let
            info = (import ./configs/${hostName}/info.nix);
            config = inputs.nixpkgs.lib.optionalAttrs (builtins.pathExists ./configs/${hostName}/default.nix) { config = ./configs/${hostName}; };
          in
          acc // builtins.foldl'
            (acc': user: acc' // {
              "${user.name}@${hostName}" = commonConfig
                (
                  {
                    inherit info;
                    user = user.name;
                  }
                  // config
                  // inputs.nixpkgs.lib.optionalAttrs (builtins.pathExists ./configs/${hostName}/${user.name}.nix) { userConfig = ./configs/${hostName}/${user.name}.nix; }
                );
            })
            { }
            info.users
        )
        { }
        (builtins.readDir ./configs);
    };
}
