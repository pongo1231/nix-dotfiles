{
  inputs = {
    nixpkgs.url = "github:pongo1231/nixpkgs/mine";

    nixpkgs-desktop-kernel = {
      url = "github:pongo1231/nixpkgs/39132664da29a8620672a2b69afe7444659f1351";
      #follows = "nixpkgs";
    };

    jovian = {
      url = "github:pongo1231/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #nixpkgs-jupiter-kernel.url = "github:nixos/nixpkgs/39132664da29a8620672a2b69afe7444659f1351";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    /*chaotic = {
      url = "github:chaotic-cx/nyx";
      inputs.nixpkgs.follows = "nixpkgs";
    };*/

    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs: {
      nixosConfigurations =
        let
          commonSystem = { system ? "x86_64-linux", type ? null, hostName, config ? null }:
            inputs.nixpkgs.lib.nixosSystem
              {
                specialArgs = {
                  inherit inputs;
                  module = file: modules/${file};
                  patch = file: patches/${file};
                  pkg = file: pkgs/${file};
                };

                modules = [
                  (_: {
                    nixpkgs.overlays = [
                      (import ./overlay.nix { inherit inputs system; })
                    ];

                    nixpkgs = {
                      hostPlatform.system = system;
                      #buildPlatform.system = "x86_64-linux";

                      config.allowUnfree = true;
                    };

                    networking = {
                      inherit hostName;
                    };
                  })

                  ./home-manager/nix.nix
                  ./modules/common
                ] ++ inputs.nixpkgs.lib.optionals (type != null) [
                  ./modules/${type}
                ] ++ inputs.nixpkgs.lib.optionals (config != null) [
                  config
                ];
              };
        in
        inputs.nixpkgs.lib.mapAttrs
          (name: value: commonSystem ((import ./configs/${name}/info.nix) // {
            hostName = name;
          }
            // inputs.nixpkgs.lib.optionalAttrs (builtins.pathExists ./configs/${name}/default.nix) { config = ./configs/${name}; })
          )
          (builtins.readDir ./configs);
    };
}
