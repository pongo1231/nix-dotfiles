{
  inputs = {
    nixpkgs.url = "github:pongo1231/nixpkgs/mine";

    nixpkgs-stable.url = "github:pongo1231/nixpkgs/66cdf593c0041cf1efc9b2889d80c9a5c497b284";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-be = {
      url = "github:GuilloteauQ/nix-be/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      commonUsers = [
        "pongo"
      ];
      commonConfig = { info, user, config ? null, userConfig ? null }:
        let
          system = if info ? system && info.system != null then info.system else "x86_64-linux";
        in
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.${system};

          extraSpecialArgs = {
            inherit system inputs;
            module = file: modules/${file};
            patch = file: patches/${file};
          };

          modules = [
            inputs.nix-index-database.hmModules.nix-index

            (_: {
              nixpkgs.overlays = [
                (import ./overlay.nix { })
              ];

              home = {
                username = user;
                homeDirectory = "/home/${user}";
              };
            })

            ./modules/common
          ] ++ inputs.nixpkgs.lib.optionals (info ? type && info.type != null) [
            ./modules/${info.type}
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
            info = import ./configs/${hostName}/info.nix;
            config = inputs.nixpkgs.lib.optionalAttrs (builtins.pathExists ./configs/${hostName}/default.nix) { config = ./configs/${hostName}; };
          in
          acc // builtins.foldl'
            (acc': user: acc' // {
              "${user}@${hostName}" = commonConfig
                (
                  {
                    inherit info user;
                  }
                  // config
                  // inputs.nixpkgs.lib.optionalAttrs (builtins.pathExists ./configs/${hostName}/${user}.nix) { userConfig = ./configs/${hostName}/${user}.nix; }
                );
            })
            { }
            commonUsers // inputs.nixpkgs.lib.optionalAttrs (info ? users) info.users
        )
        { }
        (builtins.readDir ./configs);
    };
}
