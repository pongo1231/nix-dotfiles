{ pkgs
, ...
}:
{
  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      DisplayBookmarksToolbar = "always";
      Preferences = {
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "browser.cache.disk.enable" = false;
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
      nil
      nixpkgs-fmt
      deadnix
      filelight
      vlc
      manix
      nvd
      ffmpeg
      protontricks
      appimage-run
      syncthing
      audacious
      jamesdsp
      qbittorrent
      weston
      mission-center
    ];
  };
}
