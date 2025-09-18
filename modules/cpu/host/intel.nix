_: {
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
  ];

  services.thermald.enable = true;
}
