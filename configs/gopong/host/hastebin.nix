{
  config,
  ...
}:
{
  services = {
    nginx.virtualHosts."paste.gopong.dev" = {
      forceSSL = true;
      useACMEHost = "gopong.dev";
      locations."/".proxyPass = "http://127.0.0.1:${toString config.services.haste-server.settings.port}";
    };

    haste-server.enable = true;
  };
}
