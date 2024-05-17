{ pkgs
, ...
}:
{
  xdg.configFile = {
    "discord/settings.json".text = ''
      { 
        "SKIP_HOST_UPDATE": true
      }
    '';
  };

  home.packages = with pkgs; [
    vscodium
    ghidra
    nvtop
    intel-gpu-tools
    (discord.overrideAttrs (prevAttrs: {
      desktopItem = prevAttrs.desktopItem.override { exec = "Discord --disable-smooth-scrolling --enable-features=WaylandWindowDecorations --ozone-platform-hint=auto"; };
    }))
    libreoffice
    direnv
    gimp
    audacity
    steam
    mangohud
    gamescope
    httm
    jamesdsp
  ];
}
