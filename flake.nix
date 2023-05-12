{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
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
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , nixpkgs-kernel
    , nix-alien
    , nix-ld
    }@inputs: {
      nixosConfigurations = {
        pongo-nixos = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };

          modules = [
            ({ ... }: {
              nixpkgs.overlays = [
                (final: prev: {
                  unstable = import nixpkgs-unstable {
                    inherit system;
                    config.allowUnfree = true;
                  };

                  kernel = import nixpkgs-kernel {
                    inherit system;
                    config.allowUnfree = true;
                  };

                  nbfc-linux = final.callPackage ./derivations/nbfc-linux { };
                  krunner-translator = final.unstable.libsForQt5.callPackage ./derivations/krunner-translator { };
                  snapperS = final.callPackage ./derivations/snapperS { };

                  libsForQt5 = final.unstable.libsForQt5.overrideScope' (qt5Final: qt5Prev: {
                    fcitx-qt5 = qt5Prev.fcitx5-qt;
                  });
                  plasma5Packages = final.unstable.plasma5Packages;
                  podman = final.unstable.podman;
                  podman-unwrapped = final.unstable.podman-unwrapped;
                  skopeo = final.unstable.skopeo;
                })
              ];

              disabledModules = [
                "virtualisation/container-config.nix"
                "virtualisation/containers.nix"
                "virtualisation/nixos-containers.nix"
                "virtualisation/podman/default.nix"
                "virtualisation/podman/network-socket-ghostunnel.nix"
                "virtualisation/podman/network-socket.nix"
                "tasks/lvm.nix"
                "services/networking/dnsmasq.nix"
              ];

              imports = [
                "${inputs.nixpkgs-unstable}/nixos/modules/virtualisation/container-config.nix"
                "${inputs.nixpkgs-unstable}/nixos/modules/virtualisation/containers.nix"
                "${inputs.nixpkgs-unstable}/nixos/modules/virtualisation/nixos-containers.nix"
                "${inputs.nixpkgs-unstable}/nixos/modules/virtualisation/podman/default.nix"
                "${inputs.nixpkgs-unstable}/nixos/modules/virtualisation/podman/network-socket-ghostunnel.nix"
                "${inputs.nixpkgs-unstable}/nixos/modules/virtualisation/podman/network-socket.nix"
                "${inputs.nixpkgs-unstable}/nixos/modules/tasks/lvm.nix"
                "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/dnsmasq.nix"
              ];
            })

            nix-ld.nixosModules.nix-ld

            ./derivations/nbfc-linux/service.nix

            ./configuration.nix
            ./hardware-configuration.nix
            ./nvidia.nix
            ./intel.nix
            ./snapper.nix
            ./udev.nix
            ./libvirt.nix
            ./tlp.nix
            ./gpu_passthrough.nix
            ./flatpak-fonts-icons.nix
          ];
        };
      };
    };
}
