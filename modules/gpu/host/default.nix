gpus:
{ lib, pkgs, ... }@args:
{
  imports = map (x: import (./. + "/${x}.nix") (args // { inherit gpus; })) gpus;

  programs.fish.shellAliases.nvstatus = "cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status";

  environment.systemPackages =
    with pkgs;
    lib.optionals (builtins.length gpus > 1) [ nvtopPackages.full ]
    ++ lib.optionals (builtins.length gpus == 1 && builtins.elem "amd" gpus) [ nvtopPackages.amd ]
    ++ lib.optionals (builtins.length gpus == 1 && builtins.elem "intel" gpus) [ nvtopPackages.intel ]
    ++ lib.optionals (builtins.length gpus == 1 && builtins.elem "nvidia" gpus) [
      nvtopPackages.nvidia
    ];
}
