{ pkgs
, ...
}:
{
  boot = {
    kernelParams = [
      "amd_iommu=on"
    ];
    initrd = {
      kernelModules = [ "amdgpu" ];
    };
  };
}
