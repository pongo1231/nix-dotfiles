{
  config,
  pkgs,
  ...
}:
{
  gopong.virtualHosts."paste" = {
    locations."/".proxyPass = "http://localhost:${toString config.services.haste-server.settings.port}";
    basicAuthFile = pkgs.writeText ".htpasswd" "haste:$apr1$4LvrNjr2$ywj.vBUiRw3LhmwiunVSU1";
  };

  services.haste-server.enable = true;
}
