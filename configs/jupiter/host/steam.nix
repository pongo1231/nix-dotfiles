{
  pkgs,
  ...
}:
{
  nixpkgs.overlays = [
    (
      final: prev:
      let
        # The shaders-path.patch targets src/reshade_effect_manager.cpp but
        # GetUsrDir() moved back to src/Utils/DirHelpers.cpp
        fixGamescopePatches = prev': {
          patches = [
            ../../../patches/gamescope/wlroots-libinput-switch.patch
          ]
          ++ builtins.filter (p: !(prev.lib.hasSuffix "shaders-path.patch" (toString p))) prev'.patches;

          postPatch = ''
            substituteInPlace src/Utils/DirHelpers.cpp --replace-fail 'return "/usr";' 'return "'$out'";'
            patchShebangs subprojects/libdisplay-info/tool/gen-search-table.py
            substituteInPlace src/Utils/Process.cpp --subst-var-by "gamescopereaper" "$out/bin/gamescopereaper"
            patchShebangs default_extras_install.sh
          '';
        };
      in
      {
        gamescope = prev.gamescope.overrideAttrs (
          prev':
          fixGamescopePatches prev'
          // {
            postPatch = (fixGamescopePatches prev').postPatch + ''
              substituteInPlace scripts/00-gamescope/displays/valve.steamdeck.lcd.lua --replace-fail "40, 41, 42, 43, 44, 45, 46, 47, 48, 49," "30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49,"
              substituteInPlace scripts/00-gamescope/displays/valve.steamdeck.lcd.lua --replace-fail "        60" "        60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70"
            '';
          }
        );

        # Jovian's gamescope-wsi references its own (unfixed) gamescope in a rec block
        gamescope-wsi = prev.gamescope-wsi.overrideAttrs fixGamescopePatches;

        /*
          steam = prev.steam.override {
            extraEnv = {
              LSFGVK_ENV = "1";
              LSFGVK_PERFORMANCE_MODE = "1";
              LSFGVK_MULTIPLIER = "2";
              LSFGVK_FLOW_SCALE = "0.85";
            };
          };
        */
      }
    )
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
      #environment.ENABLE_GAMESCOPE_WSI = "0";
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
        xprop
      ];

      extraPythonPackages = pythonPackages: with pythonPackages; [ click ];
    };
  };
}
