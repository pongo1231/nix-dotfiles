{
  module,
  pkgs,
  ...
}:
{
  imports = [
    (import (module /gpu) [ "amd" ])
  ];

  home.packages = with pkgs; [
    mangohud
    gamescope
    heroic
    bottles
    pcsx2
    xemu
  ];
}
