{
  config,
  lib,
  ...
}:
let
  cfg = config.pongo;
in
{
  options.pongo.ksm.forceAllProcesses = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config = {
    hardware.ksm = {
      enable = true;
      sleep = 250;
    };

    systemd = {
      services."user@".serviceConfig = lib.optionalAttrs cfg.ksm.forceAllProcesses {
        MemoryKSM = true;
      };

      tmpfiles.rules = [
        "w /sys/kernel/mm/ksm/advisor_mode - - - - scan-time"
      ];
    };
  };
}
