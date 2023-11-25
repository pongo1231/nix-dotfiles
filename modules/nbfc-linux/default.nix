{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.services.nbfc-linux;
in
{
  options.services.nbfc-linux = {
    enable = lib.mkEnableOption ''
      Enable nbfc-linux
    '';
  };

  config = lib.mkIf cfg.enable {
    systemd.services.nbfc-linux = {
      description = "nbfc-linux";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStartPre = "${pkgs.nbfc-linux}/bin/nbfc wait-for-hwmon";
        ExecStart = "${pkgs.nbfc-linux}/bin/nbfc start";
        ExecStop = "${pkgs.nbfc-linux}/bin/nbfc stop";
        Type = "forking";
        TimeoutStopSec = 20;
        Restart = "on-failure";
      };
    };

    environment.etc."nbfc/nbfc.json".text = lib.generators.toJSON { } {
      SelectedConfigId = "Acer Nitro AN515-51";
      TargetFanSpeeds = [ 1 1 ];
    };
  };
}
