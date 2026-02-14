{
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
      prismlauncher
    ];
  };
}
