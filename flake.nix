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

    lix = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.92.0-3.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {
    nixosConfigurations =
      let
        lib = inputs.nixpkgs.lib;
        commonSystem =
          {
            hostName,
            config ? null,
            system ? "x86_64-linux",
            type ? null,
            args,
          }:
          lib.nixosSystem {
            specialArgs = import ./specialArgs.nix { inherit system inputs lib; };

            modules =
              [
                (import ./modules/common {
                  inherit hostName;
                  args = builtins.removeAttrs args [
                    "system"
                    "type"
                  ];
                })
              ]
              ++ lib.optionals (type != null) [
                ./modules/${type}
              ]
              ++ lib.optionals (config != null) [
                config
              ];
          };
      in
      lib.mapAttrs
        (
          name: value:
          commonSystem (
            let
              args = import ./configs/${name}/info.nix;
            in
            {
              hostName = name;
              inherit args;
            }
            // lib.optionalAttrs (args ? system) {
              system = args.system;
            }
            // lib.optionalAttrs (args ? type) {
              type = args.type;
            }
            // lib.optionalAttrs (builtins.pathExists ./configs/${name}/default.nix) {
              config = ./configs/${name};
            }
          )
        )
        (
          lib.filterAttrs (name: value: !(builtins.pathExists ./configs/${name}/.broken)) (
            builtins.readDir ./configs
          )
        );
  };
}
