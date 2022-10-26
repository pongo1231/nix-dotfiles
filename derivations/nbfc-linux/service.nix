{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nbfc-linux;
in {
  options.services.nbfc-linux = {
    enable = mkEnableOption ''
      Enable nbfc-linux
    '';
  };

  config = mkIf cfg.enable {
    systemd.services.nbfc-linux = {
      description = "nbfc-linux";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStartPre = "${pkgs.nbfc-linux}/bin/nbfc wait-for-hwmon";
        ExecStart = "${pkgs.nbfc-linux}/bin/nbfc start";
        ExecStop = "${pkgs.nbfc-linux}/bin/nbfc stop";
        Type = "forking";
        TimeoutStopSec = 20;
        Restart = "on-failure";
      };
    };

    environment.etc."nbfc/nbfc.json".text = generators.toJSON {} {
      SelectedConfigId = "Acer Nitro AN515-51";
      TargetFanSpeeds = [1 1];
    };
  };
}
