{
  inputs = {
    nixpkgs.url = "github:pongo1231/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:pongo1231/nixpkgs/797f7dc49e0bc7fab4b57c021cdf68f595e47841";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { ... }@inputs:
    let
      commonConfig = config: inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
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
              username = config.user;
              homeDirectory = "/home/${config.user}";
            };
          })

          ./common
        ] ++ inputs.nixpkgs.lib.optionals (config ? config && config.config != null) [
          config.config
        ] ++ inputs.nixpkgs.lib.optionals (config ? type && config.type == "desktop") [
          ./desktop
        ];
      };
    in
    {
      homeConfigurations = inputs.nixpkgs.lib.concatMapAttrs
        (name: value:
          let
            config = (import ./configs/${name});
          in
          {
            "${config.user}@${inputs.nixpkgs.lib.removeSuffix ".nix" name}" = commonConfig config;
          })
        (builtins.readDir ./configs);
    };
}
