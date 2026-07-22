{
  pkgs,
  ...
}:
{
  boot.kernelParams = [
    "i915.enable_dpcd_backlight=3"
    "xe.enable_dpcd_backlight=3"
  ];

  hardware = {
    graphics.extraPackages = with pkgs; [ intel-media-driver ];

    intel-gpu-tools.enable = true;
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
