{ pkgs
, ...
}:
{
  boot = {
    kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
    ];
    initrd = {
      kernelModules = [ "amdgpu" ];
    };
  };
}
