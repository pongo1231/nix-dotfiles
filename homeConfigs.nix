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
      types ? null,
      args,
    }:
    let
      specialArgs = mkSpecialArgs user;

      userModulePath = ./common/home/users/${user};
      hostHomePath = configsDir + "/${hostName}/home";
      hostUserHomePath = configsDir + "/${hostName}/home/users/${user}";
    in
    [
      (_: {
        _module.args = specialArgs;
      })

      (import ./common/home args)
    ]
    ++ lib.optionals (types != null) (
      lib.unique (builtins.foldl' (acc: x: acc ++ specialArgs.types /${x}) [ ] types)
    )
    ++ lib.optionals (builtins.pathExists userModulePath) [ userModulePath ]
    ++ lib.optionals (builtins.pathExists hostHomePath) [ hostHomePath ]
    ++ lib.optionals (builtins.pathExists hostUserHomePath) [ hostUserHomePath ];

  mkHomeConfig =
    {
      hostName,
      user,
      system ? "x86_64-linux",
      types ? null,
      args,
    }:
    let
      specialArgs = mkSpecialArgs user;
      modules = mkModules {
        inherit
          hostName
          user
          types
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
      homeInfo = import (configsDir + "/${hostName}/info.nix");

      homeUsers =
        commonUsers ++ lib.optionals (homeInfo ? home && homeInfo.home ? users) homeInfo.home.users;

      mkOne =
        user:
        let
          key = mkUserKey hostName user;
          cfg = mkHomeConfig (
            {
              inherit hostName user;
              args =
                removeAttrs homeInfo [
                  "system"
                  "types"
                  "host"
                  "home"
                ]
                // lib.optionalAttrs (homeInfo ? home) (removeAttrs homeInfo.home [ "users" ]);
            }
            // lib.optionalAttrs (homeInfo ? system) { inherit (homeInfo) system; }
            // lib.optionalAttrs (homeInfo ? types) { inherit (homeInfo) types; }
          );
        in
        {
          name = key;
          value = cfg;
        };
    in
    map mkOne homeUsers;

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
