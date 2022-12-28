{ self
, ccache
, config
, pkgs
, lib
, specialArgs
, options
, modulesPath
, inputs
}:
let
  nur-no-pkgs = import inputs.nur {
    nurpkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  };
in
{
  imports = [
    #nur-no-pkgs.repos.ilya-fedin.modules.flatpak-icons
    inputs.nix-ld.nixosModules.nix-ld

    ./hardware-configuration.nix
    ./nvidia.nix
    ./intel.nix
    ./snapper.nix
    ./udev.nix
    ./libvirt.nix
    ./tlp.nix
    ./gpu_passthrough.nix
    ./flatpak-fonts-icons.nix
  ];

  nixpkgs.overlays = [
    (final: prev: {
      kernel_cache = (pkgs.linuxPackages_latest.kernel.override {
        stdenv = pkgs.ccacheStdenv;
        buildPackages = prev.buildPackages // {
          stdenv = pkgs.ccacheStdenv;
        };
      }).overrideDerivation (attrs: {
        preConfigure = ''
          export CCACHE_DIR=/nix/var/cache/ccache
          export CCACHE_UMASK=007
        '';
      });

      plasma5Packages = pkgs.unstable.plasma5Packages;
    })
  ];

  nix = {
    extraOptions = ''
      experimental-features = ca-derivations nix-command flakes
    '';
    settings = {
      auto-optimise-store = true;
      extra-sandbox-paths = [ "/nix/var/cache/ccache" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
      persistent = true;
    };
  };

  nixpkgs.config.allowUnfree = true;

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
      timeout = lib.mkForce 0;
    };
    tmpOnTmpfs = true;
    kernel = {
      sysctl."vm.swappiness" = 100;
      sysctl."dev.i915.perf_stream_paranoid" = 0;
      sysctl."kernel.sysrq" = 1;
    };
    kernelPackages = pkgs.linuxPackagesFor pkgs.kernel_cache;
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
      "nohz_full=1-3,5-7"
      "workqueue.power_efficient=true"
      #"intel_pstate=passive"
    ];
    kernelPatches = [
      {
        patch = null;
        extraConfig = ''
          HZ_300 y
          HZ 300
        '';
      }
      {
        patch = ./patches/linux/0001-gvt-handle-buggy-guest-driver-ppgtt-access.patch;
      }
      {
        patch = ./patches/linux/drm-i915-Enable-atomics-in-L3-for-gen9.patch;
      }
      {
        patch = ./patches/linux/drm-i915-gvt-enter-failsafe-on-hypervisor-read-failu.patch;
      }
      {
        patch = ./patches/linux/mglru.patch;
        extraConfig = ''
          LRU_GEN y
          LRU_GEN_ENABLED y
          LRU_GEN_STATS n
        '';
      }
      {
        patch = ./patches/linux/faster_memchr.patch;
      }
      {
        patch = ./patches/linux/zstd-upstream.patch;
      }
    ];
    initrd = {
      systemd.enable = true;
      kernelModules = [ "i915" "kvmgt" "vfio-iommu-type1" "mdev" ];
    };
    plymouth.enable = true;
  };
  #powerManagement.cpuFreqGovernor = "schedutil";

  zramSwap.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; # fixes --experimental flag not applying on boot
  };
  # show bluetooth headset battery level in kde
  systemd.services.bluetooth.serviceConfig.ExecStart = lib.mkForce [
    ""
    "${pkgs.bluez}/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf --experimental"
  ];

  networking.hostName = "pongo-nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    useXkbConfig = true;
  };

  services.xserver = {
    enable = true;
    displayManager.sddm = {
      enable = true;
      autoNumlock = true;
    };
    desktopManager.plasma5.enable = true;
    tty = lib.mkForce 1;
    layout = "de";
  };

  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.undervolt = {
    enable = true;
    coreOffset = -125;
    gpuOffset = -120;
    uncoreOffset = -120;
    analogioOffset = -100;
  };

  #services.nvoc = {
  #  enable = true;
  #  coreOffset = 75;
  #  memOffset = 950;
  #};

  services.nbfc-linux.enable = true;

  services.flatpak.enable = true;

  services.openssh.enable = true;

  services.persistent-evdev = {
    enable = true;
    devices = {
      persist-mouse1 = "usb-PixArt_OpticalMouse-event-mouse";
    };
  };

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

  services.fstrim.enable = true;

  # get x11 to recognize the nitro key on my acer nitro 5 laptop
  services.udev.extraHwdb = ''                                         
    evdev:input:b0011v0001p0001*
      KEYBOARD_KEY_F5=prog1
      KEYBOARD_KEY_F6=power
  '';

  networking.firewall.enable = false;

  virtualisation.podman.enable = true;

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

  programs.ccache = {
    enable = true;
    cacheDir = "/nix/var/cache/ccache";
    packageNames = [ "kernel_cache" "qemu_kvm" "intel-media-driver" ];
  };

  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.fish;

    users.pongo = {
      isNormalUser = true;
      home = "/home/pongo";
      extraGroups = [ "wheel" "libvirtd" ];
      hashedPassword = "$6$jTFwtF9QaSc/j2sI$W9nNE/f6QK1NE3uinzPYBffvxck86lmKf772auIG/8uESh.H1U9ZUUndd.DpW0tZKWOehfpJOxnGOVIxqmvh00";
    };

    # for samba
    users.guest = {
      isNormalUser = true;
      createHome = false;
      shell = pkgs.shadow;
    };
  };

  environment.systemPackages = with pkgs; with inputs.nix-alien.packages.${system}; [
    home-manager
    pulseaudio
    (distrobox.overrideAttrs
      (finalAttrs: previousAttrs: {
        version = "unstable-acb36a4";
        src = pkgs.fetchFromGitHub {
          owner = "89luca89";
          repo = "distrobox";
          rev = "acb36a427a35f451b42dd5d0f29f1c4e2fe447b9";
          sha256 = "nIqkptnP3fOviGcm8WWJkBQ0NcTE9z/BNLH/ox6qIoA=";
        };
      })) # master includes fixes regarding whitespaces in arguments passed to exported apps
    duperemove
    dconf
    nix-alien
    nix-index
    nix-index-update
    comma
    krunner-translator
    sddm-kcm
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    libsForQt5.qtstyleplugin-kvantum
    qogir-kde
    qogir-theme
    kdeconnect
    snapperS
  ];

  environment.sessionVariables = {
    GTK_USE_PORTAL = "1";
    QT_XCB_GL_INTEGRATION = "xcb_egl";
    KWIN_OPENGL_INTERFACE = "egl";
    #QT_WAYLAND_CLIENT_BUFFER_INTEGRATION = "xcomposite-egl";
    #QT_QPA_PLATFORM = "eglfs";
    WINEFSYNC = "1";
  };

  xdg.portal.enable = true;

  /*
    xdg.icons = {
    enable = true;
    icons = with pkgs; [papirus-icon-theme breeze-icons];
    };
  */

  system.stateVersion = "22.05";
}
