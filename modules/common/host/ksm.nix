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
    hardware.ksm.enable = true;

    systemd =
      {
        tmpfiles.rules = [
          "w /sys/kernel/mm/ksm/advisor_mode - - - - scan-time"
        ];
      }
      // lib.optionalAttrs cfg.ksm.forceAllProcesses {
        # https://github.com/CachyOS/CachyOS-PKGBUILDS/blob/master/cachyos-ksm-settings/PKGBUILD
        services = {
          "display-manager".serviceConfig = {
          	MemoryKSM = true;
          };
          "gdm".serviceConfig = {
            MemoryKSM = true;
          };
          "sddm".serviceConfig = {
            MemoryKSM = true;
          };
          "lightdm".serviceConfig = {
            MemoryKSM = true;
          };
          "ly".serviceConfig = {
            MemoryKSM = true;
          };
          "user@".serviceConfig = {
            MemoryKSM = true;
          };
          "getty@".serviceConfig = {
            MemoryKSM = true;
          };
        };
      };
  };
}
