{
  config,
  ...
}:
{
  services = {
    nginx.virtualHosts."paste.gopong.dev" = {
      forceSSL = true;
      useACMEHost = "gopong.dev";
      locations."/".proxyPass = "http://localhost:${toString config.services.haste-server.settings.port}";
    };

    haste-server.enable = true;
  };
}
