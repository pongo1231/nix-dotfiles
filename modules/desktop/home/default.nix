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

  home.packages =
    with pkgs;
    [
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
    ]
    ++ (import ../lsfgScripts.nix pkgs);
}
