{ pkgs
, ...
}:
{
  programs.firefox.profiles.settings = {
    "gfx.webrender.all" = true;
    "media.ffmpeg.vaapi.enabled" = true;
  };

  systemd.user = {
    services = {
      "psd" = {
        Unit = {
          Description = "Profile-sync-daemon";
          Documentation = "https://wiki.archlinux.org/index.php/Profile-sync-daemon";
          Wants = [ "psd-resync.service" ];
          RequiresMountsFor = "/home/";
          After = "winbindd.service";
        };

        Service = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          ExecStart = [ "${pkgs.profile-sync-daemon}/bin/psd startup" ];
          ExecStop = [ "${pkgs.profile-sync-daemon}/bin/psd unsync" ];
          Environment = [ "LAUNCHED_BY_SYSTEMD=1" ];
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      "psd-resync" = {
        Unit = {
          Description = "Timed resync";
          After = [ "psd.service" ];
          Wants = [ "psd-resync.timer" ];
          BindsTo = [ "psd.service" ];
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.profile-sync-daemon}/bin/psd resync";
          Environment = [ "LAUNCHED_BY_SYSTEMD=1" ];
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };

    timers = {
      "psd-resync" = {
        Unit = {
          Description = "Timer for profile-sync-daemon - 1Hour";
          BindsTo = "psd.service";
        };

        Timer = {
          OnUnitActiveSec = "1h";
        };
      };
    };
  };

  home = {
    sessionVariables.MOZ_ENABLE_WAYLAND = "1";

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
      profile-sync-daemon
      nil
      nixpkgs-fmt
      filelight
      vlc
      manix
      nvd
      ffmpeg
      protontricks
      appimage-run
    ];
  };
}
