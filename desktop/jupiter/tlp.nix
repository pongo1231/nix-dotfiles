{ lib
, ...
}: {
  services = {
    power-profiles-daemon.enable = true;

    tlp.enable = false;
    tlp.settings = {
      TLP_DEFAULT_MODE = "BAT";
      TLP_PERSISTENT_DEFAULT = 1;

      AHCI_RUNTIME_PM_ON_BAT = "auto";

      WIFI_PWR_ON_BAT = "on";

      RUNTIME_PM_ON_BAT = "auto";

      PLATFORM_PROFILE_ON_BAT = "balanced";
    };
  };
}
