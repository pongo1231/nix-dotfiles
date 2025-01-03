{ inputs
, config
, pkgs
, lib
, ...
}:
{
  boot = {
    /*kernelPackages = lib.mkDefault (pkgs.kernel.linuxPackages_latest.extend (finalAttrs: prevAttrs: {
      #zfs = pkgs.callPackage (pkg /zfs) { inherit (prevAttrs) zfs; };
    }));*/

    kernelParams = [
      #"preempt=full"
      #"nohz_full=0-N"
      "threadirqs"
      "rcu_nocbs=0-N"
      #"irqaffinity=0"
      "rcutree.enable_rcu_lazy=1"
      "rcutree.nohz_full_patience_delay=1000"
      "rcutree.use_softirq=0"
    ];

    extraModulePackages = with config.boot.kernelPackages; [ ];

    plymouth.enable = lib.mkDefault true;

    /*extraModprobeConfig = ''
      options zfs zfs_bclone_enabled=1
      options spl spl_taskq_thread_priority=0
      '';

      zfs = {
      package = pkgs.kernel.callPackage (pkg /zfs) { configFile = "user"; };
      modulePackage = pkgs.kernel.callPackage (pkg /zfs) { configFile = "kernel"; kernel = config.boot.kernelPackages.kernel; };
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

    seatd.enable = true;

    fwupd.enable = true;
  };

  virtualisation.waydroid.enable = true;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
  };

  environment.systemPackages = with pkgs; with pkgs.kdePackages; [
    kdePackages.kcmutils
    kdePackages.kdeconnect-kde
    sddm-kcm
    flatpak-kcm
    kate
    ark
    kcalc
    ocs-url
    sshfs
    krfb # for the "Virtual Display" button in kde connect to work
    maliit-keyboard
    kdePackages.qtstyleplugin-kvantum
    systemdgenie

    # for KDE info center
    clinfo
    glxinfo
    vulkan-tools
    wayland-utils
    aha
    dmidecode
  ];
}

