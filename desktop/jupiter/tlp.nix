{ lib
, ...
}: {
  services = {
    power-profiles-daemon.enable = lib.mkForce false;

    tlp.enable = true;
    tlp.settings = {
      TLP_DEFAULT_MODE = "BAT";
      TLP_PERSISTENT_DEFAULT = 1;

      AHCI_RUNTIME_PM_ON_BAT = "auto";

      WIFI_PWR_ON_BAT = "on";

      RUNTIME_PM_ON_BAT = "auto";
    };
  };
}
