{ pkgs, ... }:
{
  boot.kernelParams = [
    "amdgpu.lockup_timeout=5000,10000,10000,5000"
    "ttm.pages_min=2097152"
    "amdgpu.sched_hw_submission=4"
  ];

  environment.systemPackages = with pkgs; [ amdgpu_top ];
}
