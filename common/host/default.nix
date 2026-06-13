args:
{
  inputs,
  hostName,
  module,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../nix.nix
    ../overlay.nix
    ../sops.nix

    ./users.nix
    ./kernelParams.nix
    ./pongoKernel.nix
    ./ksm.nix
  ];

  pongo = args;

  system = {
    stateVersion = "25.11";

    nixos-init.enable = lib.mkDefault true;
    etc.overlay.enable = lib.mkDefault true;
  };

  boot = {
    loader = {
      grub.enable = lib.mkDefault false;
      systemd-boot = {
        enable = lib.mkDefault true;
        editor = false;
        consoleMode = "max";
      };
      efi.canTouchEfiVariables = lib.mkDefault true;
      timeout = lib.mkForce 0;
    };

    tmp = {
      useTmpfs = true;
      tmpfsSize = "200%";
      tmpfsHugeMemoryPages = "within_size";
    };

    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    kernel = {
      sysctl = import ./sysctl.nix config;

      sysfs.module.zswap.parameters = {
        enabled = true;
        shrinker_enabled = true;
        max_pool_percent = 50;
      };
    };

    initrd.systemd.enable = true;

    extraModprobeConfig = ''
      options snd_hda_intel power_save=1
      options kvm_amd avic=1 force_avic=1
    '';
  };

  networking = {
    inherit hostName;

    dhcpcd.enable = false;
    useNetworkd = true;

    networkmanager = {
      enable = lib.mkDefault true;
      wifi = {
        backend = "iwd";
        powersave = true;
      };
    };

    firewall.enable = false;

    nftables.enable = true;
  };

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";

  console.useXkbConfig = true;

  programs = {
    nh = {
      enable = true;
      clean.enable = true;
    };

    extra-container.enable = true;

    usbtop.enable = true;
    dconf.enable = true;
    nix-ld.enable = true;
    mosh.enable = true;
  };

  services = {
    speechd.enable = lib.mkForce false;
    udev.extraRules = import ./udev.nix { inherit config lib; };

    dbus = {
      enable = true;
      implementation = "broker";
      apparmor = "enabled";
    };

    openssh = {
      enable = true;
      settings = {
        X11Forwarding = true;
        GatewayPorts = "clientspecified";
      };
    };

    journald = {
      storage = "volatile";
      extraConfig = ''
        RuntimeMaxUse=5M
      '';
    };

    swapspace.enable = true;

    fstrim.enable = true;

    udisks2.settings."udisks2.conf".defaults = {
      btrfs_defaults = "noatime,lazytime,compress-force=zstd";
      ext4_defaults = "noatime,lazytime";
      xfs_defaults = "noatime,lazytime";
      f2fs_defaults = "noatime,lazytime";
      vfat_defaults = "noatime,lazytime";
      exfat_defaults = "noatime,lazytime";
      ntfs3_defaults = "noatime,lazytime";
    };

    ntpd-rs.enable = true;

    /*
      kmscon = {
        enable = true;
        useXkbConfig = true;
      };
    */

    userborn.enable = true;
  }
  // lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
    /*
      scx-loader = {
        enable = lib.mkDefault true;
        package = pkgs.scx.loader;
        config.default_sched = lib.mkDefault "scx_lavd";
      };
    */
  };

  security = {
    protectKernelImage = true;

    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };

    rtkit.enable = true;

    sudo-rs = {
      enable = true;
      execWheelOnly = true;
      extraConfig = ''
        Defaults timestamp_timeout=1
      '';
    };
  };

  virtualisation.podman.enable = true;

  systemd = {
    network.wait-online.enable = false;

    coredump.settings.Coredump = {
      Storage = "none";
      ProcessSizeMax = 0;
    };

    oomd = {
      enable = true;
      enableRootSlice = true;
      enableSystemSlice = true;
      enableUserSlices = true;
    };

    tmpfiles.rules = import ./tmpfiles.nix;

    services = {
      "user@".serviceConfig.Delegate = "cpu cpuset io memory pids";
      "mandb".wantedBy = lib.mkForce [ ];
    };
  };

  documentation.enable = false;

  environment = {
    etc =
      # thanks to ElvishJerricco
      (lib.mapAttrs' (name: flake: {
        name = "nix/inputs/${name}";
        value.source = flake;
      }) inputs)
      // {
        # allow imperative edits to /etc/hosts
        hosts.mode = "0644";
      };

    sessionVariables = {
      NIXPKGS_ALLOW_UNFREE = 1;
      NIXPKGS_ALLOW_INSECURE = 1;

      DXVK_NVAPI_VKREFLEX = 1;
      LOW_LATENCY_LAYER = 1;
    };

    systemPackages = with pkgs; [
      home-manager
      ddcutil
      distrobox
      sshfs
      ssh-to-age
      podman-compose
      linuxPackages.usbip
    ];
  };
}
