{
  pkgs,
  ...
}:
{
  boot = {
    kernelParams = [
      "i915.mitigations=off"
    ];

    kernel.sysctl = {
      "dev.i915.perf_stream_paranoid" = 0;
    };
  };

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    vpl-gpu-rt
  ];

  environment = {
    sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };

    systemPackages = with pkgs; [
      intel-gpu-tools
    ];
  };
}
