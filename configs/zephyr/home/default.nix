{
  inputs,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    inputs.kwin-effects-forceblur.packages.${pkgs.stdenv.hostPlatform.system}.default
    winboat
  ];
}
