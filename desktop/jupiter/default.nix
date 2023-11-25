{ config
, pkgs
, inputs
, ...
}:
let
  kernelPkgs = inputs.nixpkgs-jupiter-kernel.legacyPackages.x86_64-linux;
in
{
  imports = [
    inputs.jovian.nixosModules.jovian

    ./steam.nix
    ./tlp.nix

    "${inputs.nixpkgs-jupiter-pipewire}/nixos/modules/services/desktops/pipewire/pipewire.nix"
  ];

  disabledModules = [
    "services/desktops/pipewire/pipewire.nix"
  ];

  boot = {
    kernelPackages = kernelPkgs.linuxPackagesFor (kernelPkgs.callPackage "${inputs.jovian}/pkgs/linux-jovian" {
      kernelPatches = with kernelPkgs; [
        kernelPatches.bridge_stp_helper
        kernelPatches.request_key_helper
        kernelPatches.export-rt-sched-migrate
      ];
    });
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
    extraModulePackages = [ ];
    plymouth.enable = false;
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "sdhci_pci" ];
      kernelModules = [ "amdgpu" ];

      secrets."/keyfile" = "/keyfile";

      luks.devices = {
        root = {
          device = "/dev/disk/by-uuid/9b04c87a-2c8e-4951-99df-a6dc0f02f118";
          allowDiscards = true;
          bypassWorkqueues = true;
          keyFile = "/keyfile";
        };
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/06b87226-c5dd-4c9f-8832-838339a2e1f2";
      fsType = "btrfs";
      options = [ "subvol=root" "noatime" "compress-force=zstd:15" ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/FB14-4782";
      fsType = "vfat";
    };
  };

  powerManagement.cpuFreqGovernor = "schedutil";

  hardware = {
    cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

    opengl.extraPackages = [ pkgs.mesa-radv-jupiter ];
    opengl.extraPackages32 = [ pkgs.pkgsi686Linux.mesa-radv-jupiter ];
  };

  services = {
    xserver.displayManager.sddm.enable = false;
    pipewire.package = inputs.nixpkgs-jupiter-pipewire.legacyPackages.x86_64-linux.pipewire;
  };

  environment.systemPackages = with pkgs; [
    steam
    steamdeck-firmware
    mangohud
    gamescope
  ];
}
