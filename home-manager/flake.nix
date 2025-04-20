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
      #inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-be = {
      url = "github:GuilloteauQ/nix-be/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      #inputs.nixpkgs.follows = "nixpkgs";
    };

    isd = {
      url = "github:isd-project/isd";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      lib = inputs.nixpkgs.lib;
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
          args,
        }:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.${system};

          extraSpecialArgs = import ./specialArgs.nix { inherit system inputs lib; };

          modules =
            [
              (import ./modules/common {
                inherit user;
                args = builtins.removeAttrs args [
                  "system"
                  "type"
                ];
              })
            ]
            ++ lib.optionals (type != null) [
              ./modules/${type}
            ]
            ++ lib.optionals (config != null) [
              config
            ]
            ++ lib.optionals (userConfig != null) [
              userConfig
            ];
        };
    in
    {
      homeConfigurations = lib.foldlAttrs (
        acc: hostName: _:
        let
          args = import ./configs/${hostName}/info.nix;
        in
        acc
        // builtins.foldl' (
          acc': user:
          acc'
          // {
            "${user}@${hostName}" = commonConfig (
              {
                inherit user args;
              }
              // lib.optionalAttrs (args ? system) {
                system = args.system;
              }
              // lib.optionalAttrs (args ? type) {
                type = args.type;
              }
              // lib.optionalAttrs (builtins.pathExists ./configs/${hostName}/default.nix) {
                config = ./configs/${hostName};
              }
              // lib.optionalAttrs (builtins.pathExists ./configs/${hostName}/${user}.nix) {
                userConfig = ./configs/${hostName}/${user}.nix;
              }
            );
          }
        ) { } commonUsers
        // lib.optionalAttrs (args ? users) args.users
      ) { } (builtins.readDir ./configs);
    };
}
