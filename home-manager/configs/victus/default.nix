{
  module,
  patch,
  pkgs,
  ...
}:
{
  imports = [
    (import (module /gpu) [
      "amd"
      "nvidia"
    ])
  ];

  home.packages = with pkgs; [
    audacious
    jamesdsp
    nextcloud-client
    syncthing
    thunderbird
    birdtray
  ];
}
