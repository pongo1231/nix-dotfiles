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
        commonSystem =
          {
            hostName,
            config ? null,
            system ? "x86_64-linux",
            type ? null,
            ...
          }@args:
          inputs.nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit system inputs;
              module = file: modules/${file};
              patch = file: patches/${file};
              pkg = file: pkgs/${file};
              secret = user: file: secrets/${user}/${file};
              private = file: private/${file};
            };

            modules =
              [
                (import ./modules/common (
                  builtins.removeAttrs args [
                    "config"
                    "system"
                    "type"
                  ]
                ))
              ]
              ++ inputs.nixpkgs.lib.optionals (type != null) [
                ./modules/${type}
              ]
              ++ inputs.nixpkgs.lib.optionals (config != null) [
                config
              ];
          };
      in
      inputs.nixpkgs.lib.mapAttrs
        (
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
        )
        (
          inputs.nixpkgs.lib.filterAttrs (name: value: !(builtins.pathExists ./configs/${name}/.broken)) (
            builtins.readDir ./configs
          )
        );
  };
}
