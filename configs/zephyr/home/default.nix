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

  home.packages = with pkgs; [
    winboat
    steam-millennium
    vscodium
    prismlauncher
    ghidra
    bottles
    goverlay
    heroic
  ];
}
