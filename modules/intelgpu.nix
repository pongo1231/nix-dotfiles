{ pkgs
, ...
}:
{
  boot.kernelParams = [
    "i915.enable_guc=3"
    "i915.enable_fbc=1"
    "i915.enable_gvt=1"
    "i915.enable_psr=1"
    "i915.fastboot=1"
  ];

  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  hardware.graphics = {
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      vaapiIntel
      libvdpau-va-gl
    ];
  };
}
