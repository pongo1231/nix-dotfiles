inputs:
let
  inherit (inputs.nixpkgs) lib;

  configsDir = ./configs;
  infoLib = import ./infoLib.nix { inherit lib; };

  dirEntries = builtins.readDir configsDir;

  hostNames = builtins.filter (name: builtins.pathExists (configsDir + "/${name}/host/default.nix")) (
    builtins.attrNames dirEntries
  );

  mkSystem =
    {
      hostName,
      config ? null,
      system ? "x86_64-linux",
      roles ? null,
      args,
    }:
    let
      specialArgs = import ./specialArgs.nix {
        prefix = "host";
        isNixosModule = true;
        inherit
          inputs
          lib
          hostName
          ;
      };
    in
    lib.nixosSystem {
      inherit specialArgs;

      modules = [
        (import ./common/host args)

        (
          { ... }:
          {
            nixpkgs.hostPlatform.system = system;
          }
        )

        inputs.home-manager.nixosModules.home-manager
        (import ./homeConfigs.nix inputs {
          isNixosModule = true;
          extraSpecialArgs = import ./specialArgs.nix {
            prefix = "home";
            isNixosModule = true;
            inherit system inputs lib;
          };
          configs.${hostName} = { };
        })
      ]
      ++ lib.optionals (roles != null) (
        lib.unique (builtins.foldl' (acc: x: acc ++ specialArgs.roles /${x}) [ ] roles)
      )
      ++ lib.optionals (config != null) [ config ];
    };

  mkHost =
    name:
    let
      hostDir = configsDir + "/${name}";

      configInfo = import (hostDir + "/info.nix");
      roleInfo = infoLib.rolesInfo (configInfo.roles or [ ]);
      hostInfo = infoLib.mergeInfos [
        roleInfo.info
        configInfo
      ];

      configPath = hostDir + "/host";
    in
    mkSystem (
      {
        hostName = name;
        args =
          removeAttrs hostInfo [
            "system"
            "roles"
            "host"
            "home"
          ]
          // lib.optionalAttrs (hostInfo ? host) hostInfo.host;
      }
      // lib.optionalAttrs (hostInfo ? system) { inherit (hostInfo) system; }
      // lib.optionalAttrs (roleInfo.roles != [ ]) { roles = roleInfo.roles; }
      // lib.optionalAttrs (builtins.pathExists configPath) { config = configPath; }
    );
in
builtins.listToAttrs (
  map (name: {
    inherit name;
    value = mkHost name;
  }) hostNames
)
