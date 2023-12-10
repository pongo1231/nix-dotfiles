{ pkgs
, ...
}:
{
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="mmcblk[0-9]p[0-9]", ENV{ID_FS_USAGE}=="filesystem", RUN{program}+="${pkgs.systemd}/bin/systemd-mount -o noatime,compress-force=zstd:15,ssd_spread,commit=120 --no-block --automount=yes --collect $devnode /run/media/mmcblk0p1"
  '';

  jovian = {
    devices.steamdeck = {
      enable = true;
      enableVendorRadv = false;
      enableMesaPatches = true;
    };
    steam = {
      enable = true;
      autoStart = true;
      user = "pongo";
      desktopSession = "plasmawayland";
    };
    decky-loader = {
      enable = true;
      user = "pongo";
      extraPackages = with pkgs; [
        coreutils
        curl
        unzip
        util-linux
        gnugrep
      ];
    };
  };
}
