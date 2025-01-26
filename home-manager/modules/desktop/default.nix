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
    (discord.overrideAttrs (prevAttrs: {
      desktopItem = prevAttrs.desktopItem.override {
        exec = "Discord --disable-smooth-scrolling --enable-features=WaylandWindowDecorations --ozone-platform-hint=auto";
      };
    }))
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
