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
    inputs.chaotic.nixosModules.default

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
    kernelPatches = [
      {
        name = "amd pstate";
        patch = null;
        extraConfig = ''
          X86_AMD_PSTATE y
        '';
      }
    ];
    kernelParams = [
      "amdgpu.ppfeaturemask=0xffffffff"
    ];

    /*zfs = {
      package = lib.mkForce (kernelPkgs.callPackage ../../pkgs/zfs { configFile = "user"; });
      modulePackage = lib.mkForce (kernelPkgs.callPackage ../../pkgs/zfs { configFile = "kernel"; kernel = config.boot.kernelPackages.kernel; });
    };*/

    plymouth.enable = false;
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "sdhci_pci" ];

      secrets."/keyfile" = "/keyfile";

      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/ac2b73ac-bae8-4345-8951-36a0ee38e2f1";
          allowDiscards = true;
          bypassWorkqueues = true;
          keyFile = "/keyfile";
        };
      };
    };
  };


  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/d685db49-ec70-4854-9949-4da35a09ad31";
      fsType = "btrfs";
      options = [ "compress-force=zstd:6" "noatime" ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/0573-D9FE";
      fsType = "vfat";
    };
  };

  powerManagement.cpuFreqGovernor = "schedutil";

  hardware = {
    cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

    #opengl.extraPackages = [ pkgs.mesa-radv-jupiter ];
    #opengl.extraPackages32 = [ pkgs.pkgsi686Linux.mesa-radv-jupiter ];
  };

  networking.hostId = "a1f92a1f";

  services = {
    displayManager.sddm.enable = false;

    fstrim.enable = true;
  };

  chaotic.mesa-git.enable = true;

  environment = {
    #etc."drirc".source = "${pkgs.mesa-radv-jupiter}/share/drirc.d/00-radv-defaults.conf";

    systemPackages = with pkgs; [
      steamdeck-firmware
      mangohud
      gamescope
    ];
  };
}
