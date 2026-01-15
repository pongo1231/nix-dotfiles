{
  withSecrets,
  config,
  ...
}:
withSecrets "pongo" { store = "gopong/mollysocket.env"; } {
  "mollysocket".key = "";
}
// {
  services = {
    nginx.virtualHosts."molly.${config.networking.fqdn}" = {
      forceSSL = true;
      useACMEHost = config.networking.fqdn;
      locations."/".proxyPass = "http://localhost:${toString config.services.mollysocket.settings.port}";
    };

    mollysocket = {
      enable = true;
      environmentFile = config.sops.secrets."mollysocket".path;
      settings = {
        port = 29154;
        allowed_endpoints = [ "https://cloud.${config.networking.fqdn}" ];
      };
    };
  };
}
