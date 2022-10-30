{ config
, lib
, pkgs
, ...
}:
with lib; let
  cfg = config.services.nvoc;
in
{
  options.services.nvoc = {
    enable = mkEnableOption ''
      Enable nvidia GPU overclock
    '';

    coreOffset = mkOption {
      type = types.int;
      default = 0;
      description = "gpu_core_clock_offset_*";
    };

    memOffset = mkOption {
      type = types.int;
      default = 0;
      description = "mem_clock_offset_*";
    };
  };

  config = mkIf cfg.enable {
    environment.etc."nvoc.d/gpu0.conf".text = generators.toKeyValue { } {
      gpu = 0;
      gpu_core_clock_offset_low = toString cfg.coreOffset;
      gpu_core_clock_offset_medium = toString cfg.coreOffset;
      gpu_core_clock_offset_high = toString cfg.coreOffset;
      mem_clock_offset_low = toString cfg.memOffset;
      mem_clock_offset_medium = toString cfg.memOffset;
      mem_clock_offset_high = toString cfg.memOffset;
    };

    systemd.services.nvoc = {
      description = "Nvidia GPU overclock utility";
      wantedBy = [ "graphical.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.nvoc}/bin/nvoc --apply";
      };
    };
  };
}
