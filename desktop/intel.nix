{ config
, pkgs
, lib
, ...
}:
{
  boot = {
    kernelParams = [
      "intel_iommu=on"
      "i915.enable_guc=3"
      "i915.enable_fbc=1"
      "i915.enable_gvt=1"
      "i915.enable_psr=1"
      "i915.fastboot=1"
    ];
    initrd = {
      kernelModules = [ "i915" ];
    };
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  hardware.opengl = {
    extraPackages = with pkgs.unstable; [
      intel-media-driver
      vaapiIntel
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.unstable.pkgsi686Linux; [
      intel-media-driver
      vaapiIntel
      libvdpau-va-gl
    ];
  };
}
