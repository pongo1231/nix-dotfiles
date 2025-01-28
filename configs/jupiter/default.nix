{
  system,
  inputs,
  module,
  patch,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.jovian.nixosModules.default

    (module /wicked_kernel.nix)

    ./steam.nix
  ];

  boot = {
    plymouth.enable = false;
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "sdhci_pci"
      ];

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
      options = [
        "compress-force=zstd:6"
        "noatime"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/0573-D9FE";
      fsType = "vfat";
    };
  };

  hardware = {
    cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

    graphics =
      let
        patchMesa =
          mesa:
          mesa.overrideAttrs (
            finalAttrs: prevAttrs: {
              patches = prevAttrs.patches ++ [
                (patch /mesa/24.3.0/gamescope-limiter.patch)
              ];
            }
          );
      in
      {
        package = lib.mkForce (patchMesa pkgs.mesa.drivers);
        package32 = lib.mkForce (patchMesa pkgs.pkgsi686Linux.mesa.drivers);
      };
  };

  networking.hostId = "a1f92a1f";

  services = {
    displayManager.sddm.enable = false;

    fstrim.enable = true;

    sunshine = {
      enable = true;
      package = inputs.nixpkgs-master.legacyPackages.${system}.sunshine;
      capSysAdmin = true;
      autoStart = false;
    };
  };

  environment.systemPackages = with pkgs; [
    steamdeck-firmware
    mangohud
    gamescope
  ];
}
