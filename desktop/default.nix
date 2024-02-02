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
        (prevAttrs:
          let
            rev = "2e6b3c4d9453360a351af6148386360a3a7209b3";
          in
          {
            version = "git-${builtins.substring 0 6 rev}";

            src = pkgs.fetchFromGitHub {
              owner = "openzfs";
              repo = "zfs";
              inherit rev;
              hash = "sha256-ELQyGX5TKTJSQIXs9I2FA6YJwoiC8XlXHunLM1mmkvk=";
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

    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
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
