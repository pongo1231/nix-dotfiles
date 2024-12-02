{
  inputs = {
    nixpkgs.url = "github:pongo1231/nixpkgs/mine";

    nixpkgs-desktop-kernel = {
      url = "github:pongo1231/nixpkgs/3a3b818fe26054cea25e9895a86ff3559c218510";
      #follows = "nixpkgs";
    };

    jovian = {
      url = "github:pongo1231/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-jupiter-kernel.url = "github:nixos/nixpkgs/3a3b818fe26054cea25e9895a86ff3559c218510";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    chaotic = {
      url = "github:chaotic-cx/nyx";
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
                          qemu = final.callPackage ./pkgs/qemu_7 {
                            inherit (final.darwin.apple_sdk.frameworks) CoreServices Cocoa Hypervisor vmnet;
                            inherit (final.darwin.stubs) rez setfile;
                            inherit (final.darwin) sigtool;
                          };
                        };

                        distrobox = prev.distrobox.overrideAttrs (finalAttrs: prevAttrs: {
                          version = "git";
                          src = final.fetchFromGitHub {
                            owner = "89luca89";
                            repo = "distrobox";
                            rev = "18053c254a83750c49c08e58df2e48a0f04aef48";
                            hash = "sha256-Gqi9kot7omRrxQPy3PbpqvU3tb33pzIyMA33anzHSjw=";
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
