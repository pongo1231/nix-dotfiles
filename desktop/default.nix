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

  boot = {
    kernelPackages = lib.lowPrio (pkgs.kernel.zfs.override { removeLinuxDRM = pkgs.hostPlatform.isAarch64; }).latestCompatibleLinuxPackages;
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
    ];

    plymouth.enable = lib.mkDefault true;

    supportedFilesystems = [ "zfs" ];
    extraModprobeConfig = ''
      options zfs zfs_bclone_enabled=1 spl_taskq_thread_priority=0
    '';

    zfs = {
      package = pkgs.kernel.zfs;
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

  environment.systemPackages = with pkgs; [
    sddm-kcm
    kate
    ark
    ocs-url
    kdeconnect
    maliit-keyboard
  ];
}
