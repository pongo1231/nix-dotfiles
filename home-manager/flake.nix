{
  inputs = {
    nixpkgs.url = "github:pongo1231/nixpkgs/mine";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

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

    isd = {
      url = "github:isd-project/isd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      commonUsers = [
        "pongo"
      ];
      commonConfig =
        {
          user,
          system ? "x86_64-linux",
          type ? null,
          config ? null,
          userConfig ? null,
          ...
        }@args:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.${system};

          extraSpecialArgs = {
            inherit system inputs;
            module = file: modules/${file};
            patch = file: patches/${file};
          };

          modules =
            [
              (import ./modules/common (
                builtins.removeAttrs args [
                  "system"
                  "type"
                  "config"
                  "userConfig"
                ]
              ))
            ]
            ++ inputs.nixpkgs.lib.optionals (type != null) [
              ./modules/${type}
            ]
            ++ inputs.nixpkgs.lib.optionals (config != null) [
              config
            ]
            ++ inputs.nixpkgs.lib.optionals (userConfig != null) [
              userConfig
            ];
        };
    in
    {
      homeConfigurations = inputs.nixpkgs.lib.foldlAttrs (
        acc: hostName: _:
        let
          info = import ./configs/${hostName}/info.nix;
        in
        acc
        // builtins.foldl' (
          acc': user:
          acc'
          // {
            "${user}@${hostName}" = commonConfig (
              info
              // {
                inherit user;
              }
              // inputs.nixpkgs.lib.optionalAttrs (builtins.pathExists ./configs/${hostName}/default.nix) {
                config = ./configs/${hostName};
              }
              // inputs.nixpkgs.lib.optionalAttrs (builtins.pathExists ./configs/${hostName}/${user}.nix) {
                userConfig = ./configs/${hostName}/${user}.nix;
              }
            );
          }
        ) { } commonUsers
        // inputs.nixpkgs.lib.optionalAttrs (info ? users) info.users
      ) { } (builtins.readDir ./configs);
    };
}
