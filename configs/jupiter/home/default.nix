{
  module,
  pkgs,
  ...
}:
{
  home = {
    file = {
      "pcsx2.sh" = {
        text = ''
          #!/bin/sh
          pcsx2-qt "''${@:1}"
        '';
        executable = true;
      };

      "ppsspp.sh" = {
        text = ''
          #!/bin/sh
          ppsspp "''${@:1}"
        '';
        executable = true;
      };

      "xemu.sh" = {
        text = ''
          #!/bin/sh
          xemu "''${@:1}"
        '';
        executable = true;
      };
    };

    packages = with pkgs; [
      pcsx2
      ppsspp
      xemu
      heroic
      (bottles.override { removeWarningPopup = true; })
      atlauncher

      (pkgs.writeShellScriptBin "lsfg1x" ''
        exec env LSFG_LEGACY=0 LSFG_PERFORMANCE_MODE=1 LSFG_MULTIPLIER=1 "$@"
      '')
      (pkgs.writeShellScriptBin "lsfg2x" ''
        exec env LSFG_LEGACY=1 LSFG_PERFORMANCE_MODE=1 LSFG_MULTIPLIER=2 "$@"
      '')
      (pkgs.writeShellScriptBin "lsfg3x" ''
        exec env LSFG_LEGACY=1 LSFG_PERFORMANCE_MODE=1 LSFG_MULTIPLIER=3 "$@"
      '')
      (pkgs.writeShellScriptBin "lsfg4x" ''
        exec env LSFG_LEGACY=1 LSFG_PERFORMANCE_MODE=1 LSFG_MULTIPLIER=4 "$@"
      '')
    ];
  };
}
