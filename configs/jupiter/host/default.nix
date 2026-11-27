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
    inputs.igm5000.nixosModules.default

    (import (module /cpu/amd.nix) { })
    (import (module /gpu) [ "amd" ])
    (import (module /snapper.nix) { additionalSubvols = [ "/run/media/mmcblk0p1" ]; })

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

    kernelParams = [
      "mitigations=off"
      "rcu_nocbs=0-N"
    ];

    extraModulePackages = with config.boot.kernelPackages; [
      (stdenv.mkDerivation (final: {
        pname = "steamdeck-dkms";
        version = "git";

        src = pkgs.fetchFromGitHub {
          owner = "firlin123";
          repo = "steamdeck-dkms";
          rev = "99737c4a54e3140c7148014980c0905d0868d7ba";
          hash = "sha256-h5/jLFwWyPjSLq6v8qzL2kPMwX8BgZwU9uPrOKjM29Q=";
        };

        sourceRoot = "source";

        nativeBuildInputs = kernel.moduleBuildDependencies;

        makeFlags = kernel.extraMakeFlags ++ [
          "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
        ];

        installPhase = ''
          runHook preInstall

          for entry in mfd:steamdeck hwmon:steamdeck_hwmon leds:steamdeck_leds extcon:steamdeck_extcon; do
            dir="''${entry%%:*}"
            mod="''${entry##*:}.ko"

            install "$mod" -Dm755 -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/"$dir"
            ${pkgs.kmodigest}/bin/kmodigest "$mod"
            install "$mod.cer" -Dm444 -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/"$dir"
          done

          runHook postInstall
        '';
      }))
    ];

    plymouth.enable = false;

    binfmt.emulatedSystems = [
      "aarch64-linux"
    ];
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
        "compress-force=zstd:6"
      ];
    };
  };

  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  networking.hostId = "a1f92a1f";

  services = {
    sunshine = {
      enable = true;
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

  environment.systemPackages = with pkgs; [ jovianPackages.steamdeck-firmware ];
}
