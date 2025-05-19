{
  patch,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.pongo.ksm;
in
{
  options.pongo.ksm = {
    forceAllProcesses = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    patchSystemd = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = {
    hardware.ksm.enable = true;

    systemd =
      {
        tmpfiles.rules = [
          "w /sys/kernel/mm/ksm/advisor_mode - - - - scan-time"
        ];
      }
      // lib.optionalAttrs cfg.forceAllProcesses {
        package = lib.mkDefault (
          if (!cfg.patchSystemd) then
            pkgs.systemd
          else
            pkgs.systemd.overrideAttrs (prevAttrs: {
              patches = prevAttrs.patches ++ [ (patch /systemd/memoryksm-on-by-default.patch) ];
            })
        );

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
