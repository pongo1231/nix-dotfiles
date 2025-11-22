{
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
      DisplayBookmarksToolbar = "newtab";
      Preferences = {
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "browser.tabs.unloadOnLowMemory" = true;
        "browser.low_commit_space_threshold_percent" = 100;
        "browser.tabs.min_inactive_duration_before_unload" = 3600000;
      };
    };
  };

  home = {
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
    };

    packages =
      with pkgs;
      [
        vlc
        ffmpeg
        appimage-run
        syncthing
        qbittorrent
        weston
        looking-glass-client
        virt-manager
      ]
      ++ (import ../lsfgScripts.nix pkgs);
  };
}
