{
  withSecrets,
  config,
  ...
}:
withSecrets "pongo" { store = "sultan/mollysocket.env"; } {
  "mollysocket".key = "";
}
// {
  services = {
    nginx.virtualHosts."molly.gopong.dev" = {
      forceSSL = true;
      useACMEHost = "gopong.dev";
      locations."/".proxyPass = "http://localhost:${toString config.services.mollysocket.settings.port}";
    };

    mollysocket = {
      enable = true;
      environmentFile = config.sops.secrets."mollysocket".path;
      settings = {
        port = 29154;
        allowed_endpoints = [ "https://cloud.gopong.dev" ];
      };
    };
  };
}
