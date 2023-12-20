{ ... }:
{
  services = {
    sanoid = {
      enable = true;
      templates = {
        "base" = {
          hourly = 5;
          daily = 7;
        };

        "nosnap" = {
          hourly = 0;
          daily = 0;
          weekly = 0;
          monthly = 0;
          yearly = 0;
          autosnap = false;
        };
      };
      datasets = {
        "root/home" = { useTemplate = [ "base" ]; recursive = true; };
        "root/nosnap" = { useTemplate = [ "nosnap" ]; recursive = true; };

        "ssd" = { useTemplate = [ "base" ]; recursive = true; };
        "ssd/nosnap" = { useTemplate = [ "nosnap" ]; recursive = true; };

        "hdd" = { useTemplate = [ "base" ]; recursive = true; };
        "hdd/nosnap" = { useTemplate = [ "nosnap" ]; recursive = true; };
      };
    };
  };
}
