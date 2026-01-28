{
  inputs,
  module,
  config,
  pkgs,
  ...
}:
{
  imports = [
    inputs.jovian.nixosModules.default

    (module /cpu/amd.nix)
    (import (module /gpu) [ "amd" ])

    ./steam.nix
  ];

  boot = {
    initrd = {
      luks.devices = {
        root = {
          device = "/dev/nvme0n1p2";
          allowDiscards = true;
          bypassWorkqueues = true;
        };
      };

      unl0kr.enable = true;

      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "sdhci_pci"
      ];
    };

    kernelModules = [ "ntsync" ];

    kernelParams = [ "mitigations=off" ];

    extraModulePackages = with config.boot.kernelPackages; [
      (stdenv.mkDerivation (final: {
        pname = "steamdeck-dkms";
        version = "git";

        src = pkgs.fetchFromGitHub {
          owner = "firlin123";
          repo = "steamdeck-dkms";
          rev = "dbbc4e398be5a8219f209222056a1d70ec9cea32";
          hash = "sha256-uRsfwIFxoJ291aNRoSepehwQUmvNeLnjt86xj3PoEvU=";
        };

        sourceRoot = "source";

        nativeBuildInputs = kernel.moduleBuildDependencies;

        makeFlags = [
          "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
        ];

        installPhase = ''
          runHook preInstall

          install steamdeck.ko -Dm755 -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/mfd
          install steamdeck_hwmon.ko -Dm755 -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/hwmon
          install steamdeck_leds.ko -Dm755 -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/leds
          install steamdeck_extcon.ko -Dm755 -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/extcon

          runHook postInstall
        '';
      }))
    ];

    plymouth.enable = false;
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [
        "noatime"
        "lazytime"
        "compress-force=zstd"
      ];
    };

    "/boot" = {
      device = "/dev/nvme0n1p1";
      fsType = "vfat";
      options = [
        "noatime"
        "lazytime"
      ];
    };

    "/run/media/mmcblk0p1" = {
      device = "/dev/mmcblk0p1";
      fsType = "btrfs";
      options = [
        "x-systemd.device-timeout=5"
        "nofail"
        "noatime"
        "lazytime"
        "compress-force=zstd"
      ];
    };
  };

  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  networking.hostId = "a1f92a1f";

  services = {
    displayManager = {
      sddm.enable = false;
      gdm.enable = false;
    };

    fstrim.enable = true;

    sunshine = {
      enable = true;
      package = pkgs.sunshine;
      capSysAdmin = true;
      autoStart = false;
    };

    beesd.filesystems = {
      "-" = {
        spec = "/";
        hashTableSizeMB = 256;
        extraOptions = [ "-c 1" ];
      };

      "mmcblk0p1" = {
        spec = "/run/media/mmcblk0p1";
        hashTableSizeMB = 128;
        extraOptions = [ "-c 1" ];
      };
    };
  };

  /*
    systemd = {
      services.greetd.serviceConfig.MemoryKSM = true;
      user.services.gamescope-session.serviceConfig.MemoryKSM = true;
    };
  */

  environment.systemPackages = with pkgs; [ steamdeck-firmware ];
}
