{ config
, pkgs
, lib
, inputs
, ...
}:
let
  kernelPkgs = inputs.nixpkgs-jupiter-kernel.legacyPackages.x86_64-linux;
in
{
  imports = [
    inputs.jovian.nixosModules.default

    ./steam.nix
    ./tlp.nix

    "${inputs.nixpkgs-jupiter-pipewire}/nixos/modules/services/desktops/pipewire/pipewire.nix"
  ];

  disabledModules = [
    "services/desktops/pipewire/pipewire.nix"
  ];

  boot = {
    kernelPackages = lib.mkForce (kernelPkgs.linuxPackagesFor (kernelPkgs.callPackage "${inputs.jovian}/pkgs/linux-jovian" {
      kernelPatches = with kernelPkgs; [
        kernelPatches.bridge_stp_helper
        kernelPatches.request_key_helper
        kernelPatches.export-rt-sched-migrate
      ];
    }));

    zfs.package = lib.mkForce kernelPkgs.zfs;

    kernelPatches = [
      {
        patch = null;
        extraConfig = ''
          LRU_GEN y
          LRU_GEN_ENABLED y
        '';
      }
      {
        patch = ../../patches/linux/faster_memchr.patch;
      }
      {
        patch = ../../patches/linux/zstd-upstream.patch;
      }
    ];
    plymouth.enable = false;
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "sdhci_pci" ];
      kernelModules = [ "amdgpu" ];

      secrets."/keyfile" = "/keyfile";

      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/dca4efe8-4291-4cb6-8cce-977a83b88361";
          allowDiscards = true;
          bypassWorkqueues = true;
          keyFile = "/keyfile";
        };
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "root/root";
      fsType = "zfs";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/8C2B-5F58";
      fsType = "vfat";
    };

    "/nix" = {
      device = "root/nix";
      fsType = "zfs";
    };

    "/home" = {
      device = "root/home";
      fsType = "zfs";
    };
  };

  powerManagement.cpuFreqGovernor = "schedutil";

  hardware = {
    cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

    opengl.extraPackages = [ pkgs.mesa-radv-jupiter ];
    opengl.extraPackages32 = [ pkgs.pkgsi686Linux.mesa-radv-jupiter ];
  };

  networking.hostId = "a1f92a1f";

  services = {
    xserver.displayManager.sddm.enable = false;

    pipewire.package = inputs.nixpkgs-jupiter-pipewire.legacyPackages.x86_64-linux.pipewire;

    fstrim.enable = true;
  };

  environment = {
    etc."drirc".source = "${pkgs.mesa-radv-jupiter}/share/drirc.d/00-radv-defaults.conf";

    systemPackages = with pkgs; [
      steam
      steamdeck-firmware
      mangohud
      gamescope
    ];
  };
}
