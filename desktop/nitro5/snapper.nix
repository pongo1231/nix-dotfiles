{ ... }:
let
  mkConfig = subvolume: {
    SUBVOLUME = subvolume;
    ALLOW_GROUPS = [ "wheel" ];
    BACKGROUND_COMPARISON = true;
    NUMBER_CLEANUP = true;
    TIMELINE_MIN_AGE = 1800;
    TIMELINE_LIMIT_HOURLY = 5;
    TIMELINE_LIMIT_DAILY = 7;
    TIMELINE_LIMIT_WEEKLY = 0;
    TIMELINE_LIMIT_MONTHLY = 0;
    TIMELINE_LIMIT_YEARLY = 0;
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    NUMBER_MIN_AGE = 1800;
    NUMBER_LIMIT = 50;
    NUMBER_LIMIT_IMPORTANT = 10;
    EMPTY_PRE_POST_CLEANUP = true;
    EMPTY_PRE_POST_MIN_AGE = 1800;
  };
in
{
  services.snapper.configs = {
    home = mkConfig "/home";
    ssd = mkConfig "/media/ssd";
    hdd = mkConfig "/media/hdd";
  };
}
