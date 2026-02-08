inputs:
let
  inherit (inputs.nixpkgs) lib;

  configsDir = ./configs;

  dirEntries = builtins.readDir configsDir;

  hostNames = builtins.filter (name: !(builtins.pathExists (configsDir + "/${name}/.homeonly"))) (
    builtins.attrNames dirEntries
  );

  mkSystem =
    {
      hostName,
      config ? null,
      system ? "x86_64-linux",
      type ? null,
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
      ++ lib.optionals (type != null) (specialArgs.modules /${type})
      ++ lib.optionals (config != null) [ config ];
    };

  mkHost =
    name:
    let
      hostDir = configsDir + "/${name}";

      hostInfo = import (hostDir + "/info.nix");

      configPath = hostDir + "/host";
    in
    mkSystem (
      {
        hostName = name;
        args =
          removeAttrs hostInfo [
            "system"
            "type"
            "host"
            "home"
          ]
          // lib.optionalAttrs (hostInfo ? host) hostInfo.host;
      }
      // lib.optionalAttrs (hostInfo ? system) { inherit (hostInfo) system; }
      // lib.optionalAttrs (hostInfo ? type) { inherit (hostInfo) type; }
      // lib.optionalAttrs (builtins.pathExists configPath) { config = configPath; }
    );
in
builtins.listToAttrs (
  map (name: {
    name = name;
    value = mkHost name;
  }) hostNames
)
