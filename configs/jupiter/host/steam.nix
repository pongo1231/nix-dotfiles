{
  pkgs,
  ...
}:
{
  programs.steam.extest.enable = true;

  jovian = {
    devices.steamdeck = {
      enable = true;
      enableVendorDrivers = false;
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

      extraPythonPackages =
        pythonPackages: with pythonPackages; [
          click
        ];
    };
  };
}
