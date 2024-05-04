{ config
, pkgs
, lib
, inputs
, ...
}:
{
  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
  };

  boot = {
    kernelPackages = lib.lowPrio (pkgs.kernel.linuxPackages_latest.extend (finalAttrs: prevAttrs: {
      #zfs = pkgs.callPackage ../pkgs/zfs { inherit (prevAttrs) zfs; };
    }));

    extraModulePackages = with config.boot.kernelPackages; lib.mkDefault [ xpadneo ];

    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "nowatchdog"
      "mitigations=off"
      "i915.mitigations=off"
      "kvm.ignore_msrs=1"
      "preempt=full"
      "workqueue.power_efficient=1"
      "threadirqs"
    ];

    plymouth.enable = lib.mkDefault true;

    /*extraModprobeConfig = ''
      options zfs zfs_bclone_enabled=1
      options spl spl_taskq_thread_priority=0
    '';

    zfs = {
      package = pkgs.kernel.callPackage ../pkgs/zfs { configFile = "user"; };
      modulePackage = pkgs.kernel.callPackage ../pkgs/zfs { configFile = "kernel"; kernel = config.boot.kernelPackages.kernel; };
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
    '';*/

    kernel = {
      sysctl = {
        # https://github.com/pop-os/default-settings/blob/master_jammy/etc/sysctl.d/10-pop-default-settings.conf
        "vm.dirty_bytes" = 268435456;
        "vm.dirty_background_bytes" = 134217728;

        # yanked from linux-zen
        #"vm.compact_unevictable_allowed" = 0;
        #"vm.compaction_proactiveness" = 0;
      };
    };
  };

  hardware.opengl = {
    enable = true;
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

  environment.systemPackages = with pkgs; [
    kdePackages.kcmutils
    kdePackages.kdeconnect-kde
    sddm-kcm
    kate
    ark
    ocs-url
    sshfs
    krfb # for the "Virtual Display" button in kde connect to work
    maliit-keyboard
  ];
}
