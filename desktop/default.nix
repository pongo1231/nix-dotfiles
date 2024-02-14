{ config
, pkgs
, lib
, inputs
, ...
}:
{
  imports = [
    inputs.kde2nix.nixosModules.default
  ];

  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
  };

  boot =
    let
      patchZfs = zfs: zfs.overrideAttrs
        (finalAttrs: prevAttrs:
          let
            rev = "a5a725440bcb2f4c4554be3e489f911e3dd60412";
          in
          {
            name = builtins.replaceStrings [ prevAttrs.version ] [ finalAttrs.version ] prevAttrs.name;
            version = "git-${builtins.substring 0 6 rev}";

            src = pkgs.fetchFromGitHub {
              owner = "openzfs";
              repo = "zfs";
              inherit rev;
              hash = "sha256-D6OO9hkb/qSSEojkjdzJwAAxp4fvvZvz6D/wt94GZAY=";
            };

            meta = prevAttrs.meta // { broken = false; };
          }
        );
    in
    {
      kernelPackages = lib.lowPrio (pkgs.kernel.linuxPackages_latest.extend (finalAttrs: prevAttrs: {
        zfs = patchZfs prevAttrs.zfs;
      }));

      extraModulePackages = with config.boot.kernelPackages; lib.mkDefault [ xpadneo ];

      kernelParams = [
        "quiet"
        "splash"
        "loglevel=3"
        "nowatchdog"
        "mitigations=off"
        "kvm.ignore_msrs=1"
        "preempt=full"
        "workqueue.power_efficient=1"
        "threadirqs"
      ];

      plymouth.enable = lib.mkDefault true;

      supportedFilesystems = [ "zfs" ];
      extraModprobeConfig = ''
        options zfs zfs_bclone_enabled=1
        options spl spl_taskq_thread_priority=0
      '';

      zfs = {
        package = patchZfs pkgs.kernel.zfs;
        removeLinuxDRM = true;
      };

      # Thanks to https://toxicfrog.github.io/automounting-zfs-on-nixos/
      postBootCommands = ''
        echo "=== STARTING ZPOOL IMPORT ==="

        ${pkgs.zfs}/bin/zpool import -a
        ${pkgs.zfs}/bin/zfs load-key -a
        ${pkgs.zfs}/bin/zpool status
        ${pkgs.zfs}/bin/zfs mount -a

        echo "=== ZPOOL IMPORT COMPLETE ==="
      '';
    };

  hardware.opengl = {
    enable = true;
    package = pkgs.mesa';
    package32 = pkgs.pkgsi686Linux.mesa';
    driSupport32Bit = true;
  };

  programs.cfs-zen-tweaks.enable = true;

  services = {
    xserver = {
      displayManager.sddm = {
        enable = lib.mkDefault true;
        wayland.enable = true;
        autoNumlock = true;
      };
      desktopManager.plasma6.enable = true;
    };
  };

  environment.systemPackages = with pkgs; with inputs.kde2nix.packages.x86_64-linux; [
    flatpak-kcm
    sddm-kcm
    kate
    ark
    ocs-url
    kdeconnect-kde
    sshfs
    krfb # for the "Virtual Display" button in kde connect to work
    maliit-keyboard
  ];
}
