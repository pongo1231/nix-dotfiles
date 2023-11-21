{ self
, config
, pkgs
, lib
, specialArgs
, options
, modulesPath
, inputs
}:
{
  nix = {
    extraOptions = ''
      experimental-features = ca-derivations nix-command flakes
    '';
    settings = {
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
      persistent = true;
    };
    nixPath = [ "/etc/nix/inputs" ];
    registry.nixpkgs.flake = inputs.nixpkgs;
  };

  # thanks to ElvishJerricco
  environment.etc = (lib.mapAttrs'
    (name: flake: {
      name = "nix/inputs/${name}";
      value.source = flake.outPath;
    })
    inputs)
  // {
    # allow imperative edits to /etc/hosts
    hosts.mode = "0644";
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
      sysctl."vm.swappiness" = 180;
      sysctl."vm.page-cluster" = 0;
      sysctl."vm.watermark_boost_factor" = 0;
      sysctl."vm.watermark_scale_factor" = 125;
      sysctl."vm.max_map_count" = 2147483642; # awareness through https://www.phoronix.com/news/Fedora-39-VM-Max-Map-Count
      sysctl."dev.i915.perf_stream_paranoid" = 0;
      sysctl."kernel.sysrq" = 1;
      sysctl."kernel.core_pattern" = "/dev/null";
    };
    kernelPackages = pkgs.kernel.linuxPackages_latest;
    extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "nowatchdog"
      "mitigations=off"
      "kvm.ignore_msrs=1"
      "intel_iommu=on"
      "i915.enable_guc=3"
      "i915.enable_fbc=1"
      "i915.enable_gvt=1"
      "i915.enable_psr=1"
      "i915.fastboot=1"
      #"nohz_full=1-3,5-7"
      #"workqueue.power_efficient=true"
    ];
    /*kernelPatches = [
      {
        patch = null;
        extraConfig = ''
          HZ_300 y
          HZ 300

          FRAMEBUFFER_CONSOLE_DETECT_PRIMARY y
          DRM_FBDEV_EMULATION y
        '';
      }
      {
        patch = ./patches/linux/0001-gvt-handle-buggy-guest-driver-ppgtt-access.patch;
      }
      {
        patch = ./patches/linux/drm-i915-gvt-enter-failsafe-on-hypervisor-read-failu.patch;
      }
    ];*/
    initrd = {
      systemd.enable = true;
      kernelModules = [ "i915" "kvmgt" "vfio-iommu-type1" "mdev" ];
    };
    plymouth.enable = true;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; # fixes --experimental flag not applying on boot
  };
  # show bluetooth headset battery level in kde
  systemd.services.bluetooth.serviceConfig.ExecStart = lib.mkForce [
    ""
    "${pkgs.bluez}/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf --experimental"
  ];

  networking = {
    hostName = "pongo-nixos";
    hostId = "47fb2c6f";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    useXkbConfig = true;
  };

  services.xserver = {
    enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      autoNumlock = true;
    };
    desktopManager.plasma5.enable = true;
    #tty = lib.mkForce 1;
    layout = "de";
    libinput.enable = true;
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  services.undervolt = {
    enable = true;
    coreOffset = -90;
    gpuOffset = -90;
    uncoreOffset = -90;
    analogioOffset = -90;
  };

  services.nbfc-linux.enable = true;

  services.thermald.enable = true;

  services.flatpak.enable = true;

  services.openssh.enable = true;

  services.earlyoom.enable = true;

  services.samba = {
    enable = true;
    configText = ''
      [global]
      security = user
      map to guest = bad user
      guest account = guest
      load printers = no
      printing = bsd
      printcap name = /dev/null
      disable spoolss = yes
      show add printer wizard = no
      server multi channel support = yes
      deadtime = 30
      use sendfile = yes
      min receivefile size = 16384
      aio read size = 1
      aio write size = 1
      socket options = IPTOS_LOWDELAY TCP_NODELAY IPTOS_THROUGHPUT SO_RCVBUF=131072 SO_SNDBUF=131072
      min protocol = SMB2
      max protocol = SMB3
      client min protocol = SMB2
      client max protocol = SMB3
      client ipc min protocol = SMB2
      client ipc max protocol = SMB3
      server min protocol = SMB2
      server max protocol = SMB3
      smb ports = 445
      allow insecure wide links = yes

      [guest]
      comment = guest
      path = /media/ssd/public
      public = yes
      only guest = yes
      writable = yes
      printable = no
      inherit permissions = yes
      follow symlinks = yes
      wide links = yes
    '';
  };

  # get x11 to recognize the nitro key on my acer nitro 5 laptop
  services.udev.extraHwdb = ''                                         
    evdev:input:b0011v0001p0001*
      KEYBOARD_KEY_F5=prog1
      KEYBOARD_KEY_F6=power
  '';

  services.journald.extraConfig = ''
    SystemMaxUse=1G
  '';

  networking.firewall.enable = false;

  virtualisation = {
    podman.enable = true;
    spiceUSBRedirection.enable = true;
  };

  programs.fish = {
    enable = true;
    shellAliases = {
      nvstatus = "cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status";
      turbo_off = "echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo";
      turbo_on = "echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo";
      "cd.." = "cd ..";
      cpufreq = "watch -n.1 'grep \"^[c]pu MHz\" /proc/cpuinfo'";
    };
    shellInit = ''
      fish_add_path -maP ~/.local/bin
    '';
  };

  programs.extra-container.enable = true;

  virtualisation.waydroid.enable = true;

  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.fish;

    users.pongo = {
      isNormalUser = true;
      home = "/home/pongo";
      extraGroups = [ "wheel" "libvirtd" "networkmanager" ];
      hashedPassword = "$6$jTFwtF9QaSc/j2sI$W9nNE/f6QK1NE3uinzPYBffvxck86lmKf772auIG/8uESh.H1U9ZUUndd.DpW0tZKWOehfpJOxnGOVIxqmvh00";
    };

    # for samba
    users.guest = {
      isNormalUser = true;
      createHome = false;
      shell = pkgs.shadow;
    };
  };

  environment.systemPackages = with pkgs; with inputs.nix-alien.packages.${system}; with inputs.nix-be.packages.${system}; [
    home-manager
    pulseaudio
    (unstable.distrobox.overrideAttrs (finalAttrs: oldAttrs: {
      version = "1.6.0.1";

      src = fetchFromGitHub {
        owner = "89luca89";
        repo = "distrobox";
        rev = finalAttrs.version;
        hash = "sha256-UWrXpb20IHcwadPpwbhSjvOP1MBXic5ay+nP+OEVQE4=";
      };
    }))
    (duperemove.overrideAttrs (finalAttrs: oldAttrs: {
      version = "0.14";

      src = pkgs.fetchFromGitHub {
        owner = "markfasheh";
        repo = "duperemove";
        rev = "v${finalAttrs.version}";
        hash = "sha256-hYBD5XFjM2AEsQm7yKEHkfjwLZmXTxkY/6S3hs1uBPw=";
      };

      buildInputs = oldAttrs.buildInputs ++ [ pkgs.util-linux ];

      patches = [ ];

      makeFlags = oldAttrs.makeFlags ++ [ "CFLAGS=-Wno-error=format-security" ];
    }))
    dconf
    nix-alien
    nix-index
    nix-index-update
    comma
    krunner-translator
    sddm-kcm
    snapperS
    ubuntu_font_family
    nix-be
    ddcutil
  ];

  environment.sessionVariables = {
    GTK_USE_PORTAL = "1";
    #QT_XCB_GL_INTEGRATION = "xcb_egl";
    #KWIN_OPENGL_INTERFACE = "egl";
    WINEFSYNC = "1";
    WINEDEBUG = "-all";
    DXVK_LOG_LEVEL = "none";
    VKD3D_DEBUG = "none";
    VKD3D_SHADER_DEBUG = "none";
    NIXPKGS_ALLOW_UNFREE = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      libsForQt5.xdg-desktop-portal-kde
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };

  system.stateVersion = "22.05";
}
