{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?rev=63678e9f3d3afecfeafa0acead6239cdb447574c";
      follows = "nixpkgs-unstable";
    };
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-kernel = {
      url = "github:nixos/nixpkgs?rev=4f36fbeb7cfe125375e34944318316338d81b180";
      follows = "nixpkgs";
    };

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    nix-ld = {
      url = "github:Mic92/nix-ld/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-be = {
      url = "github:GuilloteauQ/nix-be/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , nixpkgs-unstable
    , nixpkgs-kernel
    , nix-alien
    , nix-ld
    , nix-be
    }@inputs: {
      nixosConfigurations =
        let
          commonSystem = { isVM }: nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            specialArgs = { inherit inputs; };

            modules = [
              ({ ... }: {
                nixpkgs.overlays = [
                  (final: prev: {
                    stable = import nixpkgs-stable {
                      inherit system;
                      config = {
                        allowUnfree = true;
                        permittedInsecurePackages = [
                          "python-2.7.18.6"
                        ];
                      };
                    };

                    unstable = import nixpkgs-unstable {
                      inherit system;
                      config.allowUnfree = true;
                    };

                    kernel = import nixpkgs-kernel {
                      inherit system;
                      config = {
                        allowUnfree = true;
                        nvidia.acceptLicense = true;
                      };
                    };

                    nbfc-linux = final.callPackage ./derivations/nbfc-linux { };
                    #krunner-translator = final.unstable.libsForQt5.callPackage ./derivations/krunner-translator { };
                    snapperS = final.stable.callPackage ./derivations/snapperS { };

                    /*libsForQt5 = final.unstable.libsForQt5.overrideScope' (qt5Final: qt5Prev: {
                    fcitx-qt5 = qt5Prev.fcitx5-qt;
                  });
                  plasma5Packages = final.unstable.plasma5Packages;
                  podman = final.unstable.podman;
                  podman-unwrapped = final.unstable.podman-unwrapped;
                    skopeo = final.unstable.skopeo;*/
                  })
                ];
              })

              nix-ld.nixosModules.nix-ld

              ./configuration.nix
              ./udev.nix
              ./flatpak-fonts-icons.nix
            ] ++ nixpkgs.lib.optionals (!isVM) [
              ./hardware-configuration.nix
              ./nvidia.nix
              ./intel.nix
              ./snapper.nix
              ./libvirt.nix
              ./tlp.nix
              ./gpu_passthrough.nix

              ./derivations/nbfc-linux/service.nix
            ];
          };
        in
        {
          pongo-nixos = commonSystem {
            isVM = false;
          };

          vm = commonSystem {
            isVM = true;
          };
        };
    };
}
