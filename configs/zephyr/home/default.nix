{
  inputs,
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

  home.packages = with pkgs; [ inputs.kwin-effects-forceblur.packages.${pkgs.system}.default ];
}
