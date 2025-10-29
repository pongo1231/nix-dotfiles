{
  args,
}:
{
  system,
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
    (module /nix.nix)
    (module /overlay.nix)
    (module /sops.nix)

    ./users.nix
    ./bluetooth.nix
    ./pongoKernel.nix
    ./ksm.nix
  ];

  pongo = args;

  system = {
    stateVersion = "25.11";

    rebuild.enableNg = true;
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

    kernelPackages = lib.mkDefault pkgs.linuxPackages_testing;

    kernel = {
      sysctl = import ./sysctl.nix config;

      sysfs.module.zswap.parameters = {
        enabled = true;
        shrinker_enabled = true;
        max_pool_percent = 50;
      };
    };

    initrd.systemd.enable = true;

    kernelParams = import ./kernelParams.nix config;

    extraModprobeConfig = ''
      options snd_hda_intel power_save=1
      options kvm_amd avic=1 force_avic=1
    '';
  };

  hardware.enableAllFirmware = true;

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

  console.useXkbConfig = true;

  programs = {
    nh = {
      enable = true;
      clean.enable = true;
    };

    extra-container.enable = true;

    nix-ld = {
      enable = true;
      libraries = pkgs.steam-run-free.args.multiPkgs pkgs;
    };

    usbtop.enable = true;
    dconf.enable = true;
    direnv.enable = true;
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
        GatewayPorts = "yes";
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

    envfs.enable = true;

    udisks2.settings."udisks2.conf".defaults = {
      btrfs_defaults = "noatime,lazytime,compress-force=zstd";
      ext4_defaults = "noatime,lazytime";
      xfs_defaults = "noatime,lazytime";
      f2fs_defaults = "noatime,lazytime";
      vfat_defaults = "noatime,lazytime";
      exfat_defaults = "noatime,lazytime";
      ntfs3_defaults = "noatime,lazytime";
    };
  };

  security = {
    protectKernelImage = true;

    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };

    rtkit.enable = true;
  };

  virtualisation.podman.enable = true;

  systemd = {
    network.wait-online.enable = false;

    coredump.extraConfig = ''
      Storage=none
      ProcessSizeMax=0
    '';

    oomd = {
      enable = true;
      enableRootSlice = true;
      enableSystemSlice = true;
      enableUserSlices = true;
    };

    tmpfiles.rules = import ./tmpfiles.nix;

    services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";
  };

  documentation = {
    nixos.enable = false;

    man.generateCaches = false;
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

      #PROTON_ENABLE_WAYLAND = 1;
      PROTON_USE_NTSYNC = 1;
      PROTON_USE_WOW64 = 1;
      PROTON_ENABLE_NGX_UPDATER = 1;
      DXVK_NVAPI_DRS_SETTINGS = "0x10E41E01=1,0x10E41E02=1,0x10E41E03=1,0x10E41DF3=0xffffff,0x10E41DF7=0xffffff";
    };

    systemPackages =
      with pkgs;
      [
        home-manager
        pulseaudio
        ddcutil
        #snapper
        distrobox
        udp-reverse-tunnel
        sshfs
        sops
        ssh-to-age
      ]
      ++ lib.optionals (system == "x86_64-linux") [
        scx.full
      ];
  };
}
