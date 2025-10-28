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
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    forceAllProcesses = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.ksm.enable = true;

    systemd = {
      tmpfiles.rules = [
        "w /sys/kernel/mm/ksm/advisor_mode - - - - scan-time"
      ];
    }
    // lib.optionalAttrs cfg.forceAllProcesses {
      package = pkgs.systemd.overrideAttrs (prev: {
        patches = prev.patches ++ [ (patch /systemd/memoryksm-on-by-default.patch) ];
      });
    };

    environment.systemPackages = with pkgs; [ ksmwrap ];
  };
}
