_: {
  services.snapper = {
    persistentTimer = true;
    configs =
      let
        subvols = [
          "/var/lib/postgresql"
          "/var/lib/nextcloud"
          "/var/lib/bitwarden_rs"
          "/var/vmail"
          "/var/lib/discourse"
          "/var/lib/gitlab"
          "/var/lib/haste-server"
          "/var/lib/picsur"
          "/var/lib/fmd-server"
        ];
      in
      builtins.listToAttrs (
        builtins.map (x: {
          name = x;
          value = {
            SUBVOLUME = x;
            ALLOW_GROUPS = [ "wheel" ];
            TIMELINE_CREATE = true;
            TIMELINE_CLEANUP = true;
            TIMELINE_LIMIT_YEARLY = 0;
            TIMELINE_LIMIT_QUARTERLY = 0;
            TIMELINE_LIMIT_MONTHLY = 0;
            TIMELINE_LIMIT_WEEKLY = 0;
            TIMELINE_LIMIT_DAILY = 7;
            TIMELINE_LIMIT_HOURLY = 42;
          };
        }) subvols
      );
  };
}
