{
  inputs = {
    nixpkgs.url = "github:pongo1231/nixpkgs/mine";

    nixpkgs-stable.url = "github:pongo1231/nixpkgs/b313405a5d18353dd0ce011cee1725e17b7c8756";

    nixpkgs-desktop-kernel = {
      url = "github:pongo1231/nixpkgs/9d4343b7b27a3e6f08fc22ead568233ff24bbbde";
      #follows = "nixpkgs";
    };

    jovian = {
      url = "github:pongo1231/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-jupiter-kernel.url = "github:nixos/nixpkgs/9d4343b7b27a3e6f08fc22ead568233ff24bbbde";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic = {
      url = "github:pongo1231/nyx";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { ... }@inputs: {
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
                  ({ ...
                   }: {
                    nixpkgs.overlays = [
                      (final: prev: {
                        kernel = import inputs.nixpkgs-desktop-kernel {
                          inherit system;
                          config = {
                            allowUnfree = true;
                            nvidia.acceptLicense = true;
                          };
                        };

                        nbfc-linux = final.callPackage ./pkgs/nbfc-linux { };

                        extest = final.pkgsi686Linux.callPackage ./pkgs/extest { };

                        #mesa-radv-jupiter = final.callPackage ./pkgs/mesa-radv-jupiter { mesa-radv-jupiter' = prev.mesa-radv-jupiter; };

                        steamPackages = prev.steamPackages.overrideScope (finalScope: prevScope: {
                          steam = prevScope.steam.overrideAttrs (finalAttrs: prevAttrs: {
                            postInstall = prevAttrs.postInstall + ''
                              substituteInPlace $out/share/applications/steam.desktop --replace "steam %U" "LD_PRELOAD=${final.extest}/lib/libextest.so steam %U -silent"
                            '';
                          });
                        });

                        libvirt = prev.libvirt.override (prevAttrs: { enableXen = false; });

                        openvswitch = prev.openvswitch.override { kernel = null; };

                        virtiofsd = final.callPackage ./pkgs/qemu_7/virtiofsd.nix {
                          qemu = (final.callPackage ./pkgs/qemu_7 {
                            inherit (final.darwin.apple_sdk.frameworks) CoreServices Cocoa Hypervisor vmnet;
                            inherit (final.darwin.stubs) rez setfile;
                            inherit (final.darwin) sigtool;
                          });
                        };

                        distrobox = prev.distrobox.overrideAttrs (finalAttrs: prevAttrs: {
                          version = "1.8.0";
                          src = final.fetchFromGitHub {
                            owner = "89luca89";
                            repo = "distrobox";
                            rev = finalAttrs.version;
                            hash = "sha256-e9oSTk+UlkrkRSipqjjMqwtxEvEZffVBmlSTmsIT7cU=";
                          };

                          patches = [
                            ./patches/distrobox/relative-default-icon.patch
                          ];

                          installPhase = ''
                            ./install -P $out
                          '';
                        });
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
