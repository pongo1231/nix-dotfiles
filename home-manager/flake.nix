{
  inputs = {
    nixpkgs.url = "github:pongo1231/nixpkgs/mine";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { ... }@inputs:
    let
      commonConfig = { info, config ? null }: inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.${if info ? system && info.system != null then info.system else "x86_64-linux"};
        extraSpecialArgs = { inherit inputs; };

        modules = [
          ({ ...
           }: {
            nixpkgs.overlays = [
              (final: prev: {
                # ...
              })
            ];

            home = {
              username = info.user;
              homeDirectory = "/home/${info.user}";
            };
          })

          ./modules/common
        ] ++ inputs.nixpkgs.lib.optionals (config != null) [
          config
        ] ++ inputs.nixpkgs.lib.optionals (info ? type && (info.type == "graphical" || info.type == "desktop")) [
          ./modules/graphical
        ] ++ inputs.nixpkgs.lib.optionals (info ? type && info.type == "desktop") [
          ./modules/desktop
        ];
      };
    in
    {
      homeConfigurations = inputs.nixpkgs.lib.concatMapAttrs
        (name: value:
          let
            info = (import ./configs/${name}/info.nix);
          in
          {
            "${info.user}@${name}" = commonConfig ({ inherit info; }
              // inputs.nixpkgs.lib.attrsets.optionalAttrs (builtins.pathExists ./configs/${name}/default.nix) { config = ./configs/${name}; });
          })
        (builtins.readDir ./configs);
    };
}
