{
  inputs = {
    nixpkgs.url = "github:pongo1231/nixpkgs/mine";

    nixpkgs-master.url = "github:nixos/nixpkgs";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    nixpkgs-desktop-kernel = {
      #url = "github:pongo1231/nixpkgs/0e2d2f87f0f61065ee6ccb979a1213691e74dbac";
      follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jovian = {
      url = "github:pongo1231/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #nixpkgs-jupiter-kernel.url = "github:nixos/nixpkgs/0e2d2f87f0f61065ee6ccb979a1213691e74dbac";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    /*
      chaotic = {
        url = "github:chaotic-cx/nyx";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    */

    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
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
  };

  outputs =
    inputs:
    let
      lib = inputs.nixpkgs.lib;
    in
    inputs.flake-utils.lib.eachDefaultSystem (system: {
      formatter = inputs.nixpkgs.legacyPackages.${system}.nixfmt-tree;
    })
    // {
      nixosConfigurations =
        let
          commonSystem =
            {
              hostName,
              config ? null,
              system ? "x86_64-linux",
              type ? null,
              args,
            }:
            lib.nixosSystem {
              specialArgs = import ./specialArgs.nix {
                prefix = "host";
                inherit system inputs lib;
              };

              modules =
                [
                  (import ./modules/common/host {
                    inherit hostName;
                    args = builtins.removeAttrs args [
                      "system"
                      "type"
                    ];
                  })
                ]
                ++ lib.optionals (type != null) [
                  ./modules/${type}/host
                ]
                ++ lib.optionals (config != null) [
                  config
                ];
            };
        in
        lib.mapAttrs
          (
            name: value:
            commonSystem (
              let
                args =
                  let
                    info = import ./configs/${name}/info.nix;
                  in
                  lib.optionalAttrs (info ? system) { inherit (info) system; }
                  // lib.optionalAttrs (info ? type) { inherit (info) type; }
                  // lib.optionalAttrs (info ? host) info.host;
              in
              {
                hostName = name;
                inherit args;
              }
              // lib.optionalAttrs (args ? system) {
                system = args.system;
              }
              // lib.optionalAttrs (args ? type) {
                type = args.type;
              }
              // lib.optionalAttrs (builtins.pathExists ./configs/${name}/host) {
                config = ./configs/${name}/host;
              }
            )
          )
          (
            lib.filterAttrs (name: value: !(builtins.pathExists ./configs/${name}/.broken)) (
              builtins.readDir ./configs
            )
          );

      homeConfigurations =
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
              args,
            }:
            inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = inputs.nixpkgs.legacyPackages.${system};

              extraSpecialArgs = import ./specialArgs.nix {
                prefix = "home";
                inherit system inputs lib;
              };

              modules =
                [
                  (import ./modules/common/home {
                    inherit user;
                    args = builtins.removeAttrs args [
                      "system"
                      "type"
                    ];
                  })
                ]
                ++ lib.optionals (type != null) [
                  ./modules/${type}/home
                ]
                ++ lib.optionals (config != null) [
                  config
                ]
                ++ lib.optionals (userConfig != null) [
                  userConfig
                ];
            };
        in
        lib.foldlAttrs (
          acc: hostName: _:
          let
            args =
              let
                info = import ./configs/${hostName}/info.nix;
              in
              lib.optionalAttrs (info ? system) { inherit (info) system; }
              // lib.optionalAttrs (info ? type) { inherit (info) type; }
              // lib.optionalAttrs (info ? home) info.home;
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
                // lib.optionalAttrs (builtins.pathExists ./configs/${hostName}/home) {
                  config = ./configs/${hostName}/home;
                }
                // lib.optionalAttrs (builtins.pathExists ./configs/${hostName}/home/users/${user}) {
                  userConfig = ./configs/${hostName}/home/users/${user};
                }
              );
            }
          ) { } commonUsers
          // lib.optionalAttrs (args ? users) args.users
        ) { } (builtins.readDir ./configs);
    };
}
