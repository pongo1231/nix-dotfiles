{ pkgs
, ...
}:
{
  boot = {
    kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "amd_pstate=active"
    ];
  };
}
