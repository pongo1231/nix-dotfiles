inputs:
let
  inherit (inputs.nixpkgs) lib;
  commonSystem =
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
        inherit system inputs lib;
      };
    in
    lib.nixosSystem {
      inherit specialArgs;

      modules =
        [
          (import ./modules/common/host {
            inherit hostName;
            args = builtins.removeAttrs args [
              "system"
              "type"
            ];
          })

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
        ++
          lib.optionals (type != null)
            /*
              builtins.trace (builtins.toString (
                specialArgs.modules /${type} { includeModulesInPath = true; }
              ))
            */
            (specialArgs.modules /${type} { includeModulesInPath = true; })
        ++ lib.optionals (config != null) [
          config
        ];
    };
in
lib.mapAttrs
  (
    name: _:
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
        inherit (args) system;
      }
      // lib.optionalAttrs (args ? type) {
        inherit (args) type;
      }
      // lib.optionalAttrs (builtins.pathExists ./configs/${name}/host) {
        config = ./configs/${name}/host;
      }
    )
  )
  (
    lib.filterAttrs (name: _: !(builtins.pathExists ./configs/${name}/.broken)) (
      builtins.readDir ./configs
    )
  )
