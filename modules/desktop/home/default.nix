{
  system,
  inputs,
  module,
  pkgs,
  ...
}:
{
  imports = [
    (module /graphical)
  ];

  xdg.configFile = {
    "discord/settings.json".text = ''
      { 
        "SKIP_HOST_UPDATE": true
      }
    '';
  };

  home.packages = with pkgs; [
    vesktop
    libreoffice
    gimp
    inputs.nixpkgs2.legacyPackages.${system}.audacity
    remmina
    moonlight-qt
    audacious
    jamesdsp
    nextcloud-client
    syncthing
    inputs.nixpkgs2.legacyPackages.${system}.thunderbird
    darkly

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
}
