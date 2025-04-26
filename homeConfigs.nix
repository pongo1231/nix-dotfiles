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
) { } (builtins.readDir ./configs)
