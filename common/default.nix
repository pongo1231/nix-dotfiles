{ pkgs
, lib
, inputs
, ...
}:
{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index

    ./bluetooth.nix
    ./flatpak-fonts-icons.nix
    ./udev.nix
  ];

  system.stateVersion = "22.05";

  nix = {
    extraOptions = ''
      experimental-features = ca-derivations nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    settings = {
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://pongo1231.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "pongo1231.cachix.org-1:3B6q/T1NL/YPokIFY4lthjoI6vCMKiuYjTGY3gJtZPg="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      persistent = true;
    };
    nixPath = [
      "/etc/nix/inputs"
    ];
    registry.nixpkgs.flake = inputs.nixpkgs;
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
  };

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
      timeout = lib.mkForce 0;
    };
    tmp.useTmpfs = true;
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
    ];

    extraModprobeConfig = ''
      options snd_hda_intel power_save=1
    '';
  };

  zramSwap = {
    enable = true;
    priority = 100;
    memoryPercent = 200;
  };

  hardware = {
    enableRedistributableFirmware = true;
  };

  networking = {
    networkmanager.enable = true;

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
      shellAliases = {
        "cd.." = "cd ..";
        cpufreq = "watch -n.1 'grep \"^[c]pu MHz\" /proc/cpuinfo'";
      };
      shellInit = ''
                function fish_command_not_found
        	  , $argv
                  return $status
                end

                fish_add_path -maP ~/.local/bin
      '';
    };

    extra-container.enable = true;

    command-not-found.enable = false;

    nix-index-database.comma.enable = true;

    nix-ld = {
      enable = true;
      package = pkgs.nix-ld-rs;
    };
  };

  services = {
    dbus = {
      enable = true;
      implementation = "broker";
    };

    openssh.enable = true;

    fwupd.enable = true;

    journald.extraConfig = ''
      SystemMaxUse=1G
      SystemMaxFileSize=50M
    '';

    fstrim.enable = true;
    #zfs.trim.enable = true;

    envfs.enable = true;
  };

  security.rtkit.enable = true;

  virtualisation = {
    podman.enable = true;

    waydroid.enable = true;
  };

  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.fish;

    users.pongo = {
      isNormalUser = true;
      home = "/home/pongo";
      extraGroups = [ "wheel" "input" "libvirtd" "networkmanager" "podman" "video" ];
      hashedPassword = "$6$jTFwtF9QaSc/j2sI$W9nNE/f6QK1NE3uinzPYBffvxck86lmKf772auIG/8uESh.H1U9ZUUndd.DpW0tZKWOehfpJOxnGOVIxqmvh00";
    };
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  systemd = {
    # yanked from linux-zen
    tmpfiles.rules = [
      "w /sys/kernel/mm/transparent_hugepage/defrag - - - - defer+madvise"
      "w /sys/kernel/mm/transparent_hugepage/shmem_enabled - - - - advise"
    ];

    oomd.enable = true;

    services = {
      "user@".serviceConfig.Delegate = "cpu cpuset io memory pids";
    };
  };

  environment = {
    # thanks to ElvishJerricco
    etc = (lib.mapAttrs'
      (name: flake: {
        name = "nix/inputs/${name}";
        value.source = flake.outPath;
      })
      inputs) // {
      # allow imperative edits to /etc/hosts
      hosts.mode = "0644";
    };

    sessionVariables = {
      GTK_USE_PORTAL = "1";

      MOZ_ENABLE_WAYLAND = "1";

      NIXPKGS_ALLOW_UNFREE = "1";

      DXVK_LOG_LEVEL = "none";
      VKD3D_DEBUG = "none";
      VKD3D_SHADER_DEBUG = "none";
      WINEDEBUG = "-all";
      WINEFSYNC = "1";
    };

    systemPackages = with pkgs; [
      home-manager
      pulseaudio
      distrobox
      dconf
      inputs.nix-alien.packages.${system}.nix-alien
      inputs.nix-alien.packages.${system}.nix-index-update
      inputs.nix-be.packages.${system}.nix-be
      ddcutil
      fwupd
      #snapper
      duperemove
      nixos-shell
      inputs.nixpkgs-stable.legacyPackages.${system}.compsize
    ];
  };
}
