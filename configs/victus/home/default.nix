{
  module,
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

  programs.fish.shellAliases = {
    nvstatus = "cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status";
  };

  home.packages = with pkgs; [
    audacious
    jamesdsp
    nextcloud-client
    syncthing
    thunderbird
  ];
}
