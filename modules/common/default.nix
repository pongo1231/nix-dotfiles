{ inputs
, pkgs
, lib
, ...
}:
{
  imports = [
    ./bluetooth.nix
    ./flatpak-fonts-icons.nix
    ./udev.nix
  ];

  system = {
    stateVersion = "22.05";

    rebuild.enableNg = true;
  };

  nix = {
    nixPath = [
      "/etc/nix/inputs"
    ];
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
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
        "vm.swappiness" = 180;
        "vm.page-cluster" = 0;
        "vm.watermark_boost_factor" = 0;
        "vm.watermark_scale_factor" = 125;

        "vm.max_map_count" = 2147483642; # awareness through https://www.phoronix.com/news/Fedora-39-VM-Max-Map-Count
        "dev.i915.perf_stream_paranoid" = 0;
        "kernel.sysrq" = 1;
        "kernel.core_pattern" = "/dev/null";

        # as per powertop's suggestion
        #"vm.dirty_writeback_centisecs" = 1500;

        # https://github.com/pop-os/default-settings/blob/master_noble/etc/sysctl.d/10-pop-default-settings.conf
        "vm.dirty_bytes" = 268435456;
        "vm.dirty_background_bytes" = 134217728;
        "fs.inotify.max_user_instances" = 1024;

        # Those should be defaults usually
        "vm.compact_unevictable_allowed" = 1;
        "vm.compaction_proactiveness" = 20;

        "kernel.split_lock_mitigate" = 0;
      };
    };
    initrd.systemd.enable = true;

    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "nowatchdog"
      "audit=0"
      "kvm.ignore_msrs=1"
      "ec_sys.write_support=1"
      "msr.allow_writes=on"
      "cgroup_no_v1=all"
      "mitigations=off"
      "nosoftlockup"
      "split_lock_detect=off"
    ];

    extraModprobeConfig = ''
      options snd_hda_intel power_save=1
      options kvm_amd avic=1 force_avic=1 nested=0

      blacklist iTCO_wdt
      blacklist sp5100_tco
    '';
  };

  zramSwap = {
    enable = true;
    priority = 100;
    memoryPercent = 200;
  };

  hardware = {
    enableRedistributableFirmware = true;

    ksm = {
      enable = true;
      #sleep = 50;
    };
  };

  networking = {
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

    fstrim.enable = true;
    #zfs.trim.enable = true;

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
      extraGroups = [ "wheel" "input" "libvirtd" "networkmanager" "podman" "video" "tty" "dialout" "seat" "libvirt" "kvm" "nginx" ];
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
      "w! /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise"
      "w! /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
      "w! /sys/kernel/mm/transparent_hugepage/shmem_enabled - - - - advise"
      "w! /sys/kernel/mm/transparent_hugepage/khugepaged/defrag - - - - 1"

      "w! /sys/kernel/mm/ksm/advisor_mode - - - - scan-time"
    ];

    services = {
      "user@".serviceConfig = {
        Delegate = "cpu cpuset io memory pids";
        #MemoryKSM = true;
      };

      "mglru-tweaks" = {
        enable = true;
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.bash}/bin/bash -c 'echo 2000 > /sys/kernel/mm/lru_gen/min_ttl_ms'";
        };
      };
    };
  };

  environment = {
    # thanks to ElvishJerricco
    etc = (lib.mapAttrs' (name: flake: { name = "nix/inputs/${name}"; value.source = flake.outPath; }) inputs)
      # allow imperative edits to /etc/hosts
      // { hosts.mode = "0644"; };

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
      ksm-preload
      ksm-preload32
    ];
  };
}
