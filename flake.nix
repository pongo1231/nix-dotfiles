{
  inputs = {
    nixpkgs.url = "github:pongo1231/nixpkgs/mine";

    nixpkgs-stable.url = "github:pongo1231/nixpkgs/797f7dc49e0bc7fab4b57c021cdf68f595e47841";

    nixpkgs-desktop-kernel = {
      url = "github:pongo1231/nixpkgs/632fcb59da0b4a1a270037d9959ef25475d7fdab";
      #follows = "nixpkgs";
    };

    jovian = {
      url = "github:pongo1231/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-jupiter-kernel.url = "github:nixos/nixpkgs/632fcb59da0b4a1a270037d9959ef25475d7fdab";

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-autobahn = {
      url = "github:Lassulus/nix-autobahn";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-be = {
      url = "github:GuilloteauQ/nix-be/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.1.tar.gz";
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
            inputs.nixpkgs.lib.nixosSystem {
              specialArgs = { inherit inputs; };

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

                      distrobox = prev.distrobox.overrideAttrs (finalAttrs: prevAttrs: {
                        version = "1.8.0";
                        src = final.fetchFromGitHub {
                          owner = "89luca89";
                          repo = "distrobox";
                          rev = finalAttrs.version;
                          hash = "sha256-e9oSTk+UlkrkRSipqjjMqwtxEvEZffVBmlSTmsIT7cU=";
                        };

                        installPhase = ''
                          substituteInPlace ./distrobox-generate-entry \
                                --replace-fail 'icon_default="''${XDG_DATA_HOME:-''${HOME}/.local' 'icon_default="''${XDG_DATA_HOME:-''$out'
                          ./install -P $out
                        '';
                      });

                      duperemove = prev.duperemove.overrideAttrs (finalAttrs: prevAttrs: {
                        src = final.fetchFromGitHub {
                          owner = "markfasheh";
                          repo = "duperemove";
                          rev = "c389d3d5309ed5641aae8cb5d7a255019396bf86";
                          hash = "sha256-5yyeHGttSlVro+j72VUBoscwIPd4scsQ8X2He4xWFJU=";
                        };

                        nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [ final.libbsd final.xxHash ];

                        postPatch = ''
                          substituteInPlace Makefile --replace "--std=c23" "--std=c2x"
                          substituteInPlace results-tree.h --replace "// TODO: delete this" "#include \"list.h\""
                          substituteInPlace results-tree.h --replace "struct list_head {" "struct list_head_b {"
                        '';
                      });

                      openvswitch = prev.openvswitch.override { kernel = null; };

                      virtiofsd = final.callPackage ./pkgs/qemu_7/virtiofsd.nix {
                        qemu = (final.callPackage ./pkgs/qemu_7 {
                          inherit (final.darwin.apple_sdk.frameworks) CoreServices Cocoa Hypervisor vmnet;
                          inherit (final.darwin.stubs) rez setfile;
                          inherit (final.darwin) sigtool;
                        });
                      };
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

                ./modules/common
              ] ++ inputs.nixpkgs.lib.optionals (config != null) [
                config
              ] ++ inputs.nixpkgs.lib.optionals (type == "desktop") [
                ./modules/desktop
              ] ++ inputs.nixpkgs.lib.optionals (type == "vm") [
                ./modules/vm
              ];
            };
        in
        inputs.nixpkgs.lib.concatMapAttrs
          (name: value:
            {
              ${name} = commonSystem ((import ./configs/${name}/info.nix) // { hostName = name; }
                // inputs.nixpkgs.lib.attrsets.optionalAttrs (builtins.pathExists ./configs/${name}/default.nix) { config = ./configs/${name}; });
            })
          (builtins.readDir ./configs);
    };
}
