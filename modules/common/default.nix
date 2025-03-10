{
  hostName,
  isServer ? false,
  useLixModule ? true,
  useWickedKernel ? false,
}:
{
  inputs,
  module,
  pkgs,
  lib,
  ...
}:
{
  imports =
    [
      (import (module /common/nix.nix) { inherit useLixModule; })
      (module /common/overlay)

      (module /common/bluetooth.nix)
      (import (module /common/udev.nix) { setSchedulers = !useWickedKernel; })
    ]
    ++ lib.optionals useWickedKernel [
      (import (module /common/wicked_kernel.nix) { inherit isServer; })
    ];

  system = {
    stateVersion = "22.05";

    rebuild.enableNg = true;
  };

  boot = {
    loader = {
      grub.enable = lib.mkDefault false;
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
      timeout = lib.mkForce 0;
    };

    tmp = {
      useTmpfs = true;
      tmpfsSize = "200%";
    };

    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    kernel = {
      sysctl = {
        # https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
        "vm.swappiness" = 150; # cachyos
        "vm.page-cluster" = 0;
        "vm.watermark_boost_factor" = 0;
        "vm.watermark_scale_factor" = 125;

        "vm.max_map_count" = 2147483642; # awareness through https://www.phoronix.com/news/Fedora-39-VM-Max-Map-Count
        "dev.i915.perf_stream_paranoid" = 0;
        "kernel.sysrq" = 1;
        "kernel.core_pattern" = "/dev/null";

        # https://github.com/pop-os/default-settings/blob/master_noble/etc/sysctl.d/10-pop-default-settings.conf
        "vm.dirty_bytes" = 268435456;
        "vm.dirty_background_bytes" = 67108864; # cachyos
        "fs.inotify.max_user_instances" = 1024;

        "vm.compact_unevictable_allowed" = 1;
        "vm.compaction_proactiveness" = 20;

        "kernel.split_lock_mitigate" = 0;

        # Cachyos
        "vm.vfs_cache_pressure" = 50;
        "vm.dirty_writeback_centisecs" = 1500;
        "net.core.netdev_max_backlog" = 4096;
        "fs.file-max" = 2097152;
      };
    };
    initrd.systemd.enable = true;

    kernelParams = [
      "kvm.ignore_msrs=1"
      "ec_sys.write_support=1"
      "msr.allow_writes=on"
      "cgroup_no_v1=all"
      "mitigations=off"
      "split_lock_detect=off"
      "transparent_hugepage=always"
      "transparent_hugepage_shmem=always"
      "transparent_hugepage_tmpfs=always"
    ];

    extraModprobeConfig = ''
      options snd_hda_intel power_save=1
      options kvm_amd avic=1 force_avic=1
    '';
  };

  zramSwap = {
    enable = true;
    priority = 100;
    memoryPercent = 200;
  };

  hardware = {
    enableRedistributableFirmware = true;

    ksm.enable = true;
  };

  networking = {
    inherit hostName;

    dhcpcd.enable = false;
    useNetworkd = true;

    networkmanager = {
      enable = true;
      wifi = {
        backend = "iwd";
        powersave = true;
      };
    };

    firewall.enable = false;
  };

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    useXkbConfig = true;
  };

  programs = {
    fish = {
      enable = true;
      useBabelfish = true;
    };

    nh = {
      enable = true;
      clean.enable = true;
      flake = "/etc/nixos";
    };

    extra-container.enable = true;

    nix-ld.enable = true;

    usbtop.enable = true;

    ccache = {
      enable = true;
      packageNames = [ "hello" ]; # to configure the ccache wrapper
    };
  };

  services = {
    dbus = {
      enable = true;
      implementation = "broker";
    };

    openssh = {
      enable = true;
      settings = {
        X11Forwarding = true;
        GatewayPorts = "yes";
      };
    };

    journald.extraConfig = ''
      SystemMaxUse=10M
      Storage=volatile
    '';

    power-profiles-daemon.enable = true;

    fstrim.enable = true;

    envfs.enable = true;

    irqbalance.enable = true;
  };

  security.rtkit.enable = true;

  virtualisation.podman.enable = true;

  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.fish;

    users.pongo = {
      isNormalUser = true;
      home = "/home/pongo";
      extraGroups = [
        "wheel"
        "input"
        "libvirtd"
        "networkmanager"
        "podman"
        "video"
        "tty"
        "dialout"
        "seat"
        "libvirt"
        "kvm"
        "nginx"
      ];
      hashedPassword = "$6$jTFwtF9QaSc/j2sI$W9nNE/f6QK1NE3uinzPYBffvxck86lmKf772auIG/8uESh.H1U9ZUUndd.DpW0tZKWOehfpJOxnGOVIxqmvh00";
    };
  };

  systemd = {
    network.wait-online.enable = false;

    oomd = {
      enable = true;
      enableRootSlice = true;
      enableSystemSlice = true;
      enableUserSlices = true;
    };

    tmpfiles.rules = [
      "w /sys/kernel/mm/ksm/advisor_mode - - - - scan-time"
      "w /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - 409"
      "w /sys/class/rtc/rtc0/max_user_freq - - - - 3072"
      "w /proc/sys/dev/hpet/max-user-freq  - - - - 3072"
    ];

    services = {
      "user@".serviceConfig = {
        Delegate = "cpu cpuset io memory pids";
        #MemoryKSM = true;
      };
    };
  };

  environment = {
    # thanks to ElvishJerricco
    etc =
      (lib.mapAttrs' (name: flake: {
        name = "nix/inputs/${name}";
        value.source = flake.outPath;
      }) inputs)
      # allow imperative edits to /etc/hosts
      // {
        hosts.mode = "0644";
      };

    sessionVariables = {
      GTK_USE_PORTAL = 1;

      MOZ_ENABLE_WAYLAND = 1;

      NIXPKGS_ALLOW_UNFREE = 1;

      DXVK_LOG_LEVEL = "none";
      VKD3D_DEBUG = "none";
      VKD3D_SHADER_DEBUG = "none";
      WINEDEBUG = "-all";
      WINEFSYNC = 1;
    };

    systemPackages = with pkgs; [
      home-manager
      pulseaudio
      dconf
      ddcutil
      #snapper
      distrobox
      ksmwrap
      udp-reverse-tunnel
      sshfs
    ];
  };
}
