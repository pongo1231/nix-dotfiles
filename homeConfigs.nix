inputs:
{
  isNixosModule ? false,
  extraSpecialArgs ? null,
  configs ? null,
}:
let
  inherit (inputs.nixpkgs) lib;

  commonUsers = [
    "pongo"
  ];

  configsDir = ./configs;

  dirEntries = if configs != null then configs else builtins.readDir configsDir;

  hostNames = builtins.attrNames dirEntries;

  mkSpecialArgs =
    user:
    if extraSpecialArgs != null then
      extraSpecialArgs // { inherit user; }
    else
      import ./specialArgs.nix {
        prefix = "home";
        inherit
          inputs
          isNixosModule
          user
          ;
        inherit (inputs.nixpkgs) lib;
      };

  mkModules =
    {
      hostName,
      user,
      type ? null,
      args,
    }:
    let
      specialArgs = mkSpecialArgs user;

      userModulePath = ./modules/common/home/users/${user};
      hostHomePath = configsDir + "/${hostName}/home";
      hostUserHomePath = configsDir + "/${hostName}/home/users/${user}";
    in
    [
      (_: {
        _module.args = specialArgs;
      })

      (import ./modules/common/home {
        args = builtins.removeAttrs args [
          "system"
          "type"
        ];
      })
    ]
    ++ lib.optionals (type != null) (specialArgs.modules /${type})
    ++ lib.optionals (builtins.pathExists userModulePath) [ userModulePath ]
    ++ lib.optionals (builtins.pathExists hostHomePath) [ hostHomePath ]
    ++ lib.optionals (builtins.pathExists hostUserHomePath) [ hostUserHomePath ];

  mkHomeConfig =
    {
      hostName,
      user,
      system ? "x86_64-linux",
      type ? null,
      args,
    }:
    let
      specialArgs = mkSpecialArgs user;
      modules = mkModules {
        inherit
          hostName
          user
          type
          args
          ;
      };
    in
    if isNixosModule then
      { ... }:
      {
        imports = modules;
      }
    else
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.${system};

        extraSpecialArgs = specialArgs;

        inherit modules;
      };

  mkUserKey =
    hostName: user: user + lib.optionalString (!isNixosModule && hostName != user) ("@" + hostName);

  usersForHost =
    hostName:
    let
      info = import (configsDir + "/${hostName}/info.nix");

      args =
        lib.optionalAttrs (info ? system) { inherit (info) system; }
        // lib.optionalAttrs (info ? type) { inherit (info) type; }
        // lib.optionalAttrs (info ? users) { inherit (info) users; }
        // lib.optionalAttrs (info ? home) info.home;

      hostUsers = commonUsers ++ lib.optionals (args ? users) args.users;

      mkOne =
        user:
        let
          key = mkUserKey hostName user;
          cfg = mkHomeConfig (
            {
              inherit hostName user args;
            }
            // lib.optionalAttrs (args ? system) { inherit (args) system; }
            // lib.optionalAttrs (args ? type) { inherit (args) type; }
          );
        in
        {
          name = key;
          value = cfg;
        };
    in
    map mkOne hostUsers;

  users = builtins.listToAttrs (builtins.concatLists (map usersForHost hostNames));
in
if isNixosModule then
  {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bak";
      inherit extraSpecialArgs users;
    };
  }
else
  users
