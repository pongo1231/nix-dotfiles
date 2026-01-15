{
  config,
  ...
}:
{
  services = {
    nginx.virtualHosts."paste.${config.networking.fqdn}" = {
      forceSSL = true;
      useACMEHost = config.networking.fqdn;
      locations."/".proxyPass = "http://localhost:${toString config.services.haste-server.settings.port}";
    };

    haste-server.enable = true;
  };
}
