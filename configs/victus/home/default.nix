{
  inputs,
  module,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [ inputs.kwin-effects-forceblur.packages.${pkgs.system}.default ];
}
