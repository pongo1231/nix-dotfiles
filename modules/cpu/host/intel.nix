{ pkgs, ... }:
{
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
    "intel_pstate=passive"
  ];

  services.thermald.enable = true;

  environment.systemPackages = with pkgs; [
    intel-undervolt
    powercap
  ];
}
