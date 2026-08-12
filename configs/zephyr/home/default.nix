{
  inputs,
  pkgs,
  ...
}:
{
  #services.opensnitch-ui.enable = true;

  home.packages = with pkgs; [
    winboat
    inputs.nixpkgs3.legacyPackages.${pkgs.stdenv.hostPlatform.system}.zed-editor
    pi-coding-agent
  ];
}
