{ pkgs, ... }:
{
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
  ];

  services.thermald.enable = true;

  environment.systemPackages = with pkgs; [
    intel-undervolt
  ];
}
