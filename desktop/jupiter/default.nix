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
  ];

  boot = {
    kernelPackages = lib.mkForce ((kernelPkgs.linuxPackagesFor (kernelPkgs.callPackage "${inputs.jovian}/pkgs/linux-jovian" {
      kernelPatches = with kernelPkgs; [
        kernelPatches.bridge_stp_helper
        kernelPatches.request_key_helper
        kernelPatches.export-rt-sched-migrate
      ];
    })).extend (finalAttrs: prevAttrs: {
      #zfs = pkgs.callPackage ../../pkgs/zfs { inherit (prevAttrs) zfs; };
    }));

    zfs = {
      package = lib.mkForce (kernelPkgs.callPackage ../../pkgs/zfs { configFile = "user"; });
      modulePackage = lib.mkForce (kernelPkgs.callPackage ../../pkgs/zfs { configFile = "kernel"; kernel = config.boot.kernelPackages.kernel; });
    };

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
