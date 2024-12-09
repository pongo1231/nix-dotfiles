{ pkgs
, ...
}:
{
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="block", KERNEL=="mmcblk[0-9]p[0-9]", ENV{ID_FS_USAGE}=="filesystem", RUN{program}+="${pkgs.systemd}/bin/systemd-mount -o noatime,compress-force=zstd:15,ssd_spread,commit=120 --no-block --automount=yes --collect $devnode /run/media/mmcblk0p1"
  '';

  jovian = {
    devices.steamdeck.enable = true;
    steamos = {
      enableVendorRadv = false;
      enableMesaPatches = false;
    };
    steam = {
      enable = true;
      autoStart = true;
      user = "pongo";
      desktopSession = "plasma";
    };
    decky-loader = {
      enable = true;
      enableFHSEnvironment = true;
      user = "pongo";
      extraPackages = with pkgs; [
        curl
        unzip
        util-linux
        gnugrep

        readline.out
        procps
        pciutils
        libpulseaudio
        xorg.xprop
      ];
      extraPythonPackages = pythonPackages: with pythonPackages; [
        click
      ];
    };
  };
}
