{ inputs
, module
, patch
, pkg
, config
, lib
, pkgs
, ...
}:
{
  imports = [
    (module /amdcpu.nix)
    #(import (module /nvidia.nix) { platform = "amd"; })
    (module /power.nix)
    (module /libvirt.nix)
    (import (module /samba.nix) { sharePath = "/home/pongo/Public"; })
    (import (module /wicked_kernel.nix) { })
    #(module /mesa_git.nix)
  ];

  nixpkgs.overlays = [
    (final: prev: {
      kdePackages = prev.kdePackages.overrideScope (finalScope: prevScope: {
        /*kwin = prevScope.kwin.overrideAttrs (finalAttrs: prevAttrs: {
          src = final.fetchgit {
            url = "https://invent.kde.org/plasma/kwin.git";
            rev = "4f03404fb3ebebf416f2af33f06a0b9b8c5eae65";
            hash = "sha256-oA3DOKJf6B6Jmm+wGvI4k6zvoMISh5N8lfAeST62ql0=";
          };

          postPatch = prevAttrs.postPatch + ''
            substituteInPlace src/wayland/CMakeLists.txt --replace "PRIVATE_CODE" "\"\""
            substituteInPlace src/wayland/tools/CMakeLists.txt --replace "PRIVATE_CODE" "\"\""
          '';

          buildInputs = prevAttrs.buildInputs ++ [
            final.libcanberra
            (prevScope.plasma-wayland-protocols.overrideAttrs (prevAttrs: {
              src = final.fetchgit {
                url = "https://invent.kde.org/libraries/plasma-wayland-protocols.git";
                rev = "f8915796a606f672fb3f456cde782f66d1adfa14";
                hash = "sha256-KC1ocnCLF2fMUX4MkRs2spHwPbZc91j4ALBPzF/ahDw=";
              };
            }))
          ];
        });*/
      });
    })
  ];

  boot = {
    initrd = {
      luks.devices."root" =
        {
          device = "/dev/disk/by-uuid/70a791df-646a-4684-81e3-4e943778296f";
          allowDiscards = true;
          bypassWorkqueues = true;
        };
      availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" ];
    };

    kernelPackages = lib.mkForce (pkgs.linuxPackages_wicked.extend (finalAttrs: prevAttrs: {
      ryzen-smu = prevAttrs.ryzen-smu.overrideAttrs (finalAttrs': prevAttrs': {
        patches = (prevAttrs'.patches or [ ]) ++ [ (patch /ryzen-smu/phoenix-new-pm-table-version.patch) ];
      });

      hp-omen-linux-module = finalAttrs.callPackage (pkg /hp-omen-linux-module) { };
    }));

    kernelModules = [ "vfio-pci" "kvmfr" "ec_sys" "ryzen_smu" ];

    kernelParams = [
      "amdgpu.dcdebugmask=0x10"
      #"amdgpu.ppfeaturemask=0xffffffff"
      "modprobe.blacklist=nouveau"
      #"modprobe.blacklist=btusb"
      #"vfio_pci.ids=10de:22bd" # dgpu audio
      "kvmfr.static_size_mb=32"
    ];

    extraModulePackages = with config.boot.kernelPackages; [
      (kvmfr.overrideAttrs (finalAttrs: prevAttrs: {
        src = pkgs.fetchFromGitHub {
          owner = "gnif";
          repo = "LookingGlass";
          rev = "e25492a3a36f7e1fde6e3c3014620525a712a64a";
          hash = "sha256-efAO7KLdm7G4myUv6cS1gUSI85LtTwmIm+HGZ52arj8=";
        };
        patches = [ (patch /kvmfr/string-literal-symbol-namespace.patch) ];
      }))
      #hp-omen-linux-module
      ryzen-smu
    ];

    binfmt.emulatedSystems = [
      "aarch64-linux"
    ];
  };

  fileSystems =
    {
      "/" = {
        device = "/dev/disk/by-uuid/e4c4c179-e254-46a3-b28a-acec2ce1775f";
        fsType = "btrfs";
        options = [ "compress-force=zstd:6" "noatime" ];
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/7651-3774";
        fsType = "vfat";
      };
    };

  hardware.cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;

  programs.fish.shellAliases = {
    nvstatus = "cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status";
  };

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
      capSysAdmin = true;
      autoStart = false;
    };
  };

  # binding this too early to snd_hda_intel breaks unbinding later (for vfio passthrough)
  # work around this silly bug by binding it to vfio-pci first and then rebinding it to snd_hda_intel
  /*systemd = {
          services.dgpu-audio-to-snd_hda_intel = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c 'echo 0000:01:00.1 > /sys/bus/pci/drivers/vfio-pci/unbind && echo 0000:01:00.1 > /sys/bus/pci/drivers/snd_hda_intel/bind'";
      };
          };
        };*/

  environment = {
    systemPackages = with pkgs; [
      virtiofsd
      kde-rounded-corners
    ];
  };
}

