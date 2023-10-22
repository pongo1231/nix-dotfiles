{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?rev=f99e5f03cc0aa231ab5950a15ed02afec45ed51a";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-kernel.url = "github:nixos/nixpkgs?rev=897876e4c484f1e8f92009fd11b7d988a121a4e7";

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixpkgs";
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
                    stable = nixpkgs-stable.legacyPackages.${system};

                    unstable = import nixpkgs-unstable {
                      inherit system;
                      config.allowUnfree = true;
                    };

                    kernel = import nixpkgs-kernel {
                      inherit system;
                      config.allowUnfree = true;
                    };

                    nbfc-linux = final.callPackage ./derivations/nbfc-linux { };
                    #krunner-translator = final.unstable.libsForQt5.callPackage ./derivations/krunner-translator { };
                    snapperS = final.callPackage ./derivations/snapperS { };

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
