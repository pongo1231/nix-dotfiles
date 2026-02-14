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
    inputs.nixpkgs2.legacyPackages.${pkgs.stdenv.hostPlatform.system}.vscode-fhs
    prismlauncher
    ghidra
    bottles
  ];
}
