{
  pkgs,
  ...
}:
{
  boot = {
    kernelParams = [
      "i915.mitigations=off"
      "xe.mitigations=off"
    ];

    kernel.sysctl = {
      "dev.i915.perf_stream_paranoid" = 0;
    };
  };

  hardware = {
    graphics.extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
    ];

    intel-gpu-tools.enable = true;
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
