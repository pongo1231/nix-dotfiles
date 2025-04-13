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
    systemd.services."user@".serviceConfig = lib.optionalAttrs cfg.ksm.forceAllProcesses {
      MemoryKSM = true;
    };
  };
}
