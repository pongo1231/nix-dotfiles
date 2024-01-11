{ pkgs
, lib
, inputs
, ...
}:
{
  imports = [
    ./bluetooth.nix
    ./flatpak-fonts-icons.nix
    ./udev.nix
  ];

  system.stateVersion = "22.05";

  nix = {
    extraOptions = ''
      experimental-features = ca-derivations nix-command flakes
    '';
    settings = {
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://0uptime.cachix.org"
      ];
      trusted-public-keys = [
        "0uptime.cachix.org-1:ctw8yknBLg9cZBdqss+5krAem0sHYdISkw/IFdRbYdE="
      ];
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
  environment = {
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
      # https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
      sysctl."vm.swappiness" = 180;
      sysctl."vm.page-cluster" = 0;
      sysctl."vm.watermark_boost_factor" = 0;
      sysctl."vm.watermark_scale_factor" = 125;

      sysctl."vm.max_map_count" = 2147483642; # awareness through https://www.phoronix.com/news/Fedora-39-VM-Max-Map-Count
      sysctl."dev.i915.perf_stream_paranoid" = 0;
      sysctl."kernel.sysrq" = 1;
      sysctl."kernel.core_pattern" = "/dev/null";
    };
    initrd.systemd.enable = true;
  };

  zramSwap = {
    enable = true;
    priority = 100;
    memoryPercent = 200;
  };

  hardware = {
    enableRedistributableFirmware = true;

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
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
      shellAliases = {
        "cd.." = "cd ..";
        cpufreq = "watch -n.1 'grep \"^[c]pu MHz\" /proc/cpuinfo'";
      };
      shellInit = ''
        fish_add_path -maP ~/.local/bin
      '';
    };

    extra-container.enable = true;
  };

  services = {
    xserver = {
      enable = true;
      layout = "de";
      libinput.enable = true;
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    flatpak.enable = true;

    openssh.enable = true;

    earlyoom.enable = true;

    fwupd.enable = true;

    journald.extraConfig = ''
      SystemMaxUse=1G
      SystemMaxFileSize=50M
    '';

    fstrim.enable = true;
    zfs.trim.enable = true;
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
      extraGroups = [ "wheel" "input" "libvirtd" "networkmanager" ];
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

  environment.systemPackages = with pkgs; [
    unstable.home-manager
    pulseaudio
    (unstable.distrobox.overrideAttrs (finalAttrs: oldAttrs: {
      version = "1.6.0.1";

      src = fetchFromGitHub {
        owner = "89luca89";
        repo = "distrobox";
        rev = finalAttrs.version;
        hash = "sha256-UWrXpb20IHcwadPpwbhSjvOP1MBXic5ay+nP+OEVQE4=";
      };

      patches = [
        ../patches/distrobox/always-mount-nix.patch
      ];

      postFixup = oldAttrs.postFixup + ''
        mkdir -p $out/share/distrobox
        echo 'container_additional_volumes="/nix:/nix"' > $out/share/distrobox/distrobox.conf
      '';
    }))
    dconf
    inputs.nix-alien.packages.${system}.nix-alien
    nix-index
    inputs.nix-alien.packages.${system}.nix-index-update
    comma
    krunner-translator
    ubuntu_font_family
    inputs.nix-be.packages.${system}.nix-be
    ddcutil
    fwupd
  ];
}
