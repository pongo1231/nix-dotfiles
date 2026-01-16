{
  config,
  pkgs,
  ...
}:
{
  services = {
    nginx.virtualHosts."paste.${config.networking.fqdn}" = {
      forceSSL = true;
      useACMEHost = config.networking.fqdn;
      locations."/".proxyPass = "http://localhost:${toString config.services.haste-server.settings.port}";
      basicAuthFile = pkgs.writeText ".htpasswd" "haste:$apr1$4LvrNjr2$ywj.vBUiRw3LhmwiunVSU1";
    };

    haste-server.enable = true;
  };
}
