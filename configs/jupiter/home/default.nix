{
  inputs,
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

      # Override the steamdeck-dsp access restrictions, which grant clients on the
      # pipewire-0 socket only read/execute permissions and thereby break volume
      # and output-device control from the Plasma applet (and pactl).
      # Written to ~/.config/wireplumber/wireplumber.conf.d/ (XDG_CONFIG_HOME),
      # which WirePlumber loads after XDG_DATA_DIRS, so this wins over the
      # steamdeck-dsp access.conf.
      "wireplumber/wireplumber.conf.d/access.conf" = {
        text = ''
          access.permission-managers = [
            {
              name = "default-all"
              default_permissions = "all"
              rules = [
                {
                  matches = [
                    { media.class = "Audio/Sink/Internal" }
                    { media.class = "Audio/Source/Internal" }
                    { media.class = "Stream/Input/Audio/Internal" }
                    { media.class = "Stream/Output/Audio/Internal" }
                  ]
                  actions = { set-permissions = "" }
                }
              ]
            }
          ]

          access.rules = [
            {
              matches = [ { access = "flatpak" media.category = "Manager" } ]
              actions = { update-props = { permission_manager_name = "default-all" } }
            }
            {
              matches = [ { access = "flatpak" } ]
              actions = { update-props = { permission_manager_name = "default-all" } }
            }
            {
              matches = [ { access = "restricted" } ]
              actions = { update-props = { permission_manager_name = "default-all" } }
            }
            {
              matches = [ { access = "default" } ]
              actions = { update-props = { permission_manager_name = "default-all" } }
            }
          ]
        '';
      };
    };

    packages = with pkgs; [
      pcsx2
      ppsspp
      xemu
      heroic
      bottles
      prismlauncher
      inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.opencode
    ];
  };
}
