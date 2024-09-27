{ config
, pkgs
, lib
, inputs
, ...
}:
{
  boot = {
    kernelPackages = lib.lowPrio (pkgs.kernel.linuxPackages_latest.extend (finalAttrs: prevAttrs: {
      #zfs = pkgs.callPackage ../pkgs/zfs { inherit (prevAttrs) zfs; };
    }));

    kernelParams = [
      "workqueue.power_efficient=1"
      #"preempt=full"
      "nohz_full=0-N"
      "threadirqs"
      "rcu_nocbs=0-N"
      "rcutree.enable_rcu_lazy=1"
      "rcutree.nohz_full_patience_delay=1000"
      "rcutree.use_softirq=0"
      "nosoftlockup"
    ];

    extraModulePackages = with config.boot.kernelPackages; [ ];

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

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    xpadneo.enable = true;
  };

  #programs.cfs-zen-tweaks.enable = true;

  services = {
    displayManager.sddm = {
      enable = lib.mkDefault true;
      wayland.enable = true;
      autoNumlock = true;
    };
    desktopManager.plasma6.enable = true;
    xserver.xkb.layout = "de";

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    flatpak.enable = true;
  };

  systemd.services = {
    "mglru-tweaks" = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c 'echo 1000 > /sys/kernel/mm/lru_gen/min_ttl_ms'";
      };
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
    virt-manager
    kdePackages.qtstyleplugin-kvantum
    systemdgenie

    # for KDE info center
    clinfo
    glxinfo
    vulkan-tools
    wayland-utils
    aha
  ];
}

