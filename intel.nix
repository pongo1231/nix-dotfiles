{ pkgs
, lib
, ...
}: {
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiIntel
      libvdpau-va-gl
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [ intel-media-driver vaapiIntel libvdpau-va-gl ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
