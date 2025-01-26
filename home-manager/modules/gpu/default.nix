gpus:
{
  pkgs,
  lib,
  ...
}:
{
  home.packages =
    with pkgs;
    lib.optionals (builtins.length gpus > 1) [ nvtopPackages.full ]
    ++ lib.optionals (builtins.elem "amd" gpus) [ amdgpu_top ]
    ++ lib.optionals (builtins.length gpus == 1 && builtins.elem "amd" gpus) [ nvtopPackages.amd ]
    ++ lib.optionals (builtins.elem "intel" gpus) [ intel-gpu-tools ]
    ++ lib.optionals (builtins.length gpus == 1 && builtins.elem "intel" gpus) [ nvtopPackages.intel ]
    ++ lib.optionals (builtins.length gpus == 1 && builtins.elem "nvidia" gpus) [
      nvtopPackages.nvidia
    ];
}
