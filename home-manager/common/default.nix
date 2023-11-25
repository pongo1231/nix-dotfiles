{ config
, pkgs
, inputs
, ...
}: {
  imports = [
    ./helpers.nix
    ./suspender.nix
  ];

  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  nixpkgs.config.allowUnfreePredicate = pkg: true;

  programs = {
    git = {
      enable = true;
      userName = "pongo1231";
      userEmail = "pongo1999712@gmail.com";
    };

    firefox = {
      profiles = {
        settings = {
          "gfx.webrender.all" = true;
          "media.ffmpeg.vaapi.enabled" = true;
        };
      };
    };
  };

  xdg.configFile = {
    "nix/inputs/nixpkgs".source = inputs.nixpkgs;

    "distrobox/distrobox.conf".text = ''
      container_image_default="docker.io/library/archlinux"
      container_init_hook="echo '$(uname -n)' > /etc/hostname"
      non_interactive="1"
    '';
  };

  home = {
    stateVersion = "22.05";

    sessionVariables = {
      NIX_PATH = "nixpkgs=${config.xdg.configHome}/nix/inputs/nixpkgs$\{NIX_PATH:+:$NIX_PATH}";
      MOZ_ENABLE_WAYLAND = "1";
    };

    pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.breeze-icons;
      name = "Breeze";
    };

    file = {
      # Wrapper for running flatpak inside steam-session
      # Steam-rom-manager doesn't let us point to a non-existing file
      # and the dir of the flatpak executable differs inside the FHS container :(
      "flatpak.sh" = {
        text = ''
          #!/bin/sh
          flatpak "''${@:1}"
        '';
        executable = true;
      };

      # Workaround for plasma-browser-integration
      ".mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json".source = "${pkgs.plasma-browser-integration}/lib/mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json";
    };

    packages = with pkgs; [
      firefox
      gotop
      kate
      p7zip
      pciutils
      ark
      killall
      lsof
      ocs-url
      nil
      nixpkgs-fmt
      filelight
      compsize
      powertop
      htop
      wget
      smartmontools
      usbutils
      vlc
      unrar
      file
      gdu
      e2fsprogs
      manix
      nix-du
      nix-tree
      nvd
      kdeconnect
      ffmpeg
      protontricks
      appimage-run
      maliit-keyboard
    ];
  };
}
