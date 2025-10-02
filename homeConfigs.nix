inputs:
{
  isNixosModule ? false,
  extraSpecialArgs ? null,
  configs ? null,
}:
let
  commonUsers = [
    "pongo"
  ];

  inherit (inputs.nixpkgs) lib;

  commonConfig =
    {
      user,
      system ? "x86_64-linux",
      type ? null,
      config ? null,
      userConfig ? null,
      args,
    }:
    let
      specialArgs =
        if extraSpecialArgs != null then
          extraSpecialArgs // { inherit user; }
        else
          import ./specialArgs.nix {
            prefix = "home";
            inherit
              system
              inputs
              isNixosModule
              user
              ;
            inherit (inputs.nixpkgs) lib;
          };
      modules = [
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
      ++ lib.optionals (config != null) [
        config
      ]
      ++ lib.optionals (userConfig != null) [
        userConfig
      ];
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

  users = lib.foldlAttrs (
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
        "${user}${lib.optionalString (!isNixosModule && hostName != user) "@${hostName}"}" = commonConfig (
          {
            inherit user args;
          }
          // lib.optionalAttrs (args ? system) {
            inherit (args) system;
          }
          // lib.optionalAttrs (args ? type) {
            inherit (args) type;
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
  ) { } (if configs != null then configs else builtins.readDir ./configs);
in
if isNixosModule then
  {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      inherit extraSpecialArgs users;
    };
  }
else
  users
