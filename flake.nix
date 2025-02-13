{
  inputs = {
    nixpkgs.url = "github:pongo1231/nixpkgs/mine";

    nixpkgs-master.url = "github:nixos/nixpkgs";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    nixpkgs-desktop-kernel = {
      #url = "github:pongo1231/nixpkgs/0e2d2f87f0f61065ee6ccb979a1213691e74dbac";
      follows = "nixpkgs";
    };

    jovian = {
      url = "github:pongo1231/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #nixpkgs-jupiter-kernel.url = "github:nixos/nixpkgs/0e2d2f87f0f61065ee6ccb979a1213691e74dbac";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    /*
      chaotic = {
        url = "github:chaotic-cx/nyx";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    */

    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {
    nixosConfigurations =
      let
        specialArgs = {
          module = file: modules/${file};
          patch = file: patches/${file};
          pkg = file: pkgs/${file};
        };

        commonSystem =
          {
            hostName,
            system ? "x86_64-linux",
            type ? null,
            commonArgs ? { },
            config ? null,
          }:
          inputs.nixpkgs.lib.nixosSystem {
            specialArgs = specialArgs // {
              inherit system inputs;
            };

            modules =
              [
                (_: {
                  nixpkgs.overlays = [
                    (import ./overlay.nix {
                      inherit system inputs;
                      inherit (specialArgs) pkg;
                      inherit (inputs.nixpkgs) lib;
                    })
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

                ./nix.nix
                (import ./modules/common commonArgs)
              ]
              ++ inputs.nixpkgs.lib.optionals (type != null) [
                ./modules/${type}
              ]
              ++ inputs.nixpkgs.lib.optionals (config != null) [
                config
              ];
          };
      in
      inputs.nixpkgs.lib.mapAttrs (
        name: value:
        commonSystem (
          (import ./configs/${name}/info.nix)
          // {
            hostName = name;
          }
          // inputs.nixpkgs.lib.optionalAttrs (builtins.pathExists ./configs/${name}/default.nix) {
            config = ./configs/${name};
          }
        )
      ) (builtins.readDir ./configs);
  };
}
