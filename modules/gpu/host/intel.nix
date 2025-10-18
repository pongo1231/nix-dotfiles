{
  pkgs,
  ...
}:
{
  boot = {
    kernelParams = [
      "i915.mitigations=off"
      "xe.mitigations=off"
      "i915.enable_dpcd_backlight=1"
      "xe.enable_dpcd_backlight=1"
    ];

    kernel.sysctl."dev.i915.perf_stream_paranoid" = 0;
  };

  hardware = {
    graphics.extraPackages = with pkgs; [ intel-media-driver ];

    intel-gpu-tools.enable = true;
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
