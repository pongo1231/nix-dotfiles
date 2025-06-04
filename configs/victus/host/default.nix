{
  system,
  inputs,
  module,
  patch,
  pkg,
  config,
  pkgs,
  ...
}:
{
  imports = [
    (module /cpu/amd.nix)
    (import (module /gpu/nvidia.nix) { platform = "amd"; })
    (module /libvirt.nix)
    (import (module /samba.nix) { sharePath = "/home/pongo/Public"; })
  ];

  boot = {
    initrd = {
      luks.devices."root" = {
        device = "/dev/disk/by-uuid/70a791df-646a-4684-81e3-4e943778296f";
        allowDiscards = true;
        bypassWorkqueues = true;
      };
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usb_storage"
        "sd_mod"
      ];
    };

    kernelModules = [
      "vfio-pci"
      "kvmfr"
      "ec_sys"
      "ryzen_smu"
    ];

    kernelParams = [
      #"amdgpu.dcdebugmask=0x10"
      "modprobe.blacklist=nouveau"
      "kvmfr.static_size_mb=32"
    ];

    extraModulePackages =
      with config.boot.kernelPackages;
      let
        llvmMod =
          pkg: pkg
        /*
          .overrideAttrs (
            final: prev: {

                inherit (kernel) stdenv;
                makeFlags = (prev.makeFlags or [ ]) ++ [
                  "LLVM=1"
                  "CC=${final.stdenv.cc}/bin/clang"
                ];
                hardeningDisable = [ "strictoverflow" ];
            }
          )
        */
        ;
      in
      [
        (llvmMod kvmfr)

        (llvmMod (callPackage (pkg /hp-omen-linux-module) { }))

        (llvmMod (
          ryzen-smu.overrideAttrs (prev: {
            patches = (prev.patches or [ ]) ++ [ (patch /ryzen-smu/phoenix-new-pm-table-version.patch) ];

            installPhase = ''
              install ryzen_smu.ko -Dm444 -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/ryzen_smu
              install ${
                llvmMod (
                  stdenv.mkDerivation {
                    pname = "monitor-cpu";
                    inherit (prev) version src;

                    makeFlags = [
                      "-C userspace"
                    ];

                    installPhase = "install userspace/monitor_cpu -Dm755 -t $out/bin";
                  }
                )
              }/bin/monitor_cpu -Dm755 -t $out/bin
            '';
          })
        ))
      ];

    binfmt.emulatedSystems = [
      "aarch64-linux"
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/e4c4c179-e254-46a3-b28a-acec2ce1775f";
      fsType = "btrfs";
      options = [
        "compress-force=zstd:6"
        "noatime"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/7651-3774";
      fsType = "vfat";
    };
  };

  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  services = {
    udev.extraRules = ''
      SUBSYSTEM=="kvmfr", OWNER="pongo", GROUP="wheel", MODE="0600"
    '';

    keyd = {
      enable = true;
      keyboards.main.settings = {
        alt = {
          kp1 = "end";
          kp2 = "down";
          kp3 = "pagedown";
          kp4 = "left";
          kp6 = "right";
          kp7 = "home";
          kp8 = "up";
          kp9 = "pageup";
          kp0 = "insert";
          kpdot = "delete";
        };
      };
    };

    sunshine = {
      enable = true;
      package = pkgs.sunshine;
      capSysAdmin = true;
      autoStart = false;
    };

    printing.enable = true;

    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };

  environment.systemPackages = with pkgs; [
    virtiofsd
    kde-rounded-corners
    freerdp
    inputs.winapps.packages.${system}.winapps
    inputs.winapps.packages.${system}.winapps-launcher
  ];
}
