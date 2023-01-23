{ pkgs
, lib
, ...
}: {        
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    #package = lib.mkForce pkgs.unstable.mesa;
    #package32 = lib.mkForce pkgs.unstable.pkgsi686Linux.mesa;
    extraPackages = with pkgs.unstable; [
      intel-media-driver
    ];
    extraPackages32 = with pkgs.unstable.pkgsi686Linux; [ intel-media-driver ];
  };
}
