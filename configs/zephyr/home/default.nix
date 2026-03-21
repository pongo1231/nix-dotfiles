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
    inputs.nixpkgs2.legacyPackages.${pkgs.stdenv.hostPlatform.system}.winboat
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
