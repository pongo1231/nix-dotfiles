{
  inputs,
  pkgs,
  ...
}:
{
  programs.mangohud = {
    enable = true;
    enableSessionWide = true;
  };

  #services.opensnitch-ui.enable = true;

  home.packages = with pkgs; [
    winboat
    #steam-millennium
    steam
    vscodium
    prismlauncher
    ghidra
    bottles
    goverlay
    heroic
    looking-glass-client
    protontricks
  ];
}
