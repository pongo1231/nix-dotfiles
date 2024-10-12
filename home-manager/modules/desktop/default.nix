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
    nvtopPackages.full
    intel-gpu-tools
    amdgpu_top
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
    remmina
    moonlight-qt
  ];
}
