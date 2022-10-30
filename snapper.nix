{ config, ... }:
let
  extraConfig = ''
    ALLOW_GROUPS="wheel"
    BACKGROUND_COMPARISON="yes"
    NUMBER_CLEANUP="yes"
    TIMELINE_MIN_AGE="1800"
    TIMELINE_LIMIT_HOURLY="5"
    TIMELINE_LIMIT_DAILY="7"
    TIMELINE_LIMIT_WEEKLY="0"
    TIMELINE_LIMIT_MONTHLY="0"
    TIMELINE_LIMIT_YEARLY="0"
    TIMELINE_CREATE="yes"
    TIMELINE_CLEANUP="yes"
    NUMBER_MIN_AGE="1800"
    NUMBER_LIMIT="50"
    NUMBER_LIMIT_IMPORTANT="10"
    EMPTY_PRE_POST_CLEANUP="yes"
    EMPTY_PRE_POST_MIN_AGE="1800"
  '';
in
{
  services.snapper.configs = {
    home = {
      subvolume = "/home";
      inherit extraConfig;
    };
    ssd = {
      subvolume = "/media/ssd";
      inherit extraConfig;
    };
    hdd = {
      subvolume = "/media/hdd";
      inherit extraConfig;
    };
  };
}
