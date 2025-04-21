{
  module,
  pkgs,
  ...
}:
{
  imports = [
    (module /graphical)
  ];

  xdg.configFile = {
    "discord/settings.json".text = ''
      { 
        "SKIP_HOST_UPDATE": true
      }
    '';
  };

  home.packages = with pkgs; [
    vesktop
    libreoffice
    gimp
    audacity
    steam
    mangohud
    gamescope
    remmina
    moonlight-qt
  ];
}
