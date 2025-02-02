{
  inputs,
  pkgs,
  ...
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
    sessionVariables.MOZ_ENABLE_WAYLAND = 1;

    file = {
      # Wrapper for running flatpak inside steam-session
      # Steam-rom-manager doesn't let us point to a non-existing file
      # and the dir of the flatpak executable differs inside the FHS container :(
      "flatpak.sh" = {
        text = ''
          #!/bin/sh
          flatpak --user "''${@:1}"
        '';
        executable = true;
      };

      # Workaround for plasma-browser-integration
      ".mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json".source =
        "${pkgs.plasma-browser-integration}/lib/mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json";
    };

    packages = with pkgs; [
      filelight
      vlc
      ffmpeg
      protontricks
      appimage-run
      syncthing
      audacious
      #jamesdsp
      qbittorrent
      weston
      looking-glass-client
      virt-manager
    ];
  };
}
