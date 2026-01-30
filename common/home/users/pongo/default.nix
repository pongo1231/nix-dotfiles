{ ... }:
{
  imports = [ ./fish.nix ];

  programs.git.settings.user = {
    name = "pongo1231";
    email = "pongo@ecmec.eu";
  };
}
