{
  pkgs,
  ...
}:
{
  nixpkgs.overlays = [
    (final: prev: {
      gamescope = prev.gamescope.overrideAttrs (prev': {
        postPatch = prev'.postPatch + ''
          substituteInPlace scripts/00-gamescope/displays/valve.steamdeck.lcd.lua --replace-fail "40, 41, 42, 43, 44, 45, 46, 47, 48, 49," "30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49,"
          substituteInPlace scripts/00-gamescope/displays/valve.steamdeck.lcd.lua --replace-fail "        60" "        60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70"
        '';
      });

      steam = prev.steam.override {
        extraEnv = {
          LSFGVK_ENV = "1";
          LSFGVK_PERFORMANCE_MODE = "1";
          LSFGVK_MULTIPLIER = "2";
          LSFGVK_FLOW_SCALE = "0.85";
        };
      };
    })
  ];

  programs.steam.extest.enable = true;

  jovian = {
    devices.steamdeck = {
      enable = true;
      enableVendorDrivers = false;
      enableKernelPatches = false;
    };

    steam = {
      enable = true;
      autoStart = true;
      user = "pongo";
      desktopSession = "plasma";
      environment.ENABLE_GAMESCOPE_WSI = "0";
    };

    steamos = {
      enableEarlyOOM = false;
      enableZram = false;
      enableSysctlConfig = false;
      enableDefaultCmdlineConfig = false;
      enableAutoMountUdevRules = false;
    };

    workarounds.ignoreMissingKernelModules = false;

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

      extraPythonPackages = pythonPackages: with pythonPackages; [ click ];
    };
  };
}
