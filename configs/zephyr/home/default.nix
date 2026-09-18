{
  pkgs,
  ...
}:
{
  #services.opensnitch-ui.enable = true;

  home.packages = with pkgs; [
    winboat
    zed-editor
  ];
}
