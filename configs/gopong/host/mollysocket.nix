{
  withSecrets,
  config,
  ...
}:
withSecrets "pongo" { store = "gopong/mollysocket.env"; } {
  "mollysocket".key = "";
}
// {
  gopong.virtualHosts."molly".locations."/".proxyPass =
    "http://localhost:${toString config.services.mollysocket.settings.port}";

  services.mollysocket = {
    enable = true;
    environmentFile = config.sops.secrets."mollysocket".path;
    settings = {
      port = 29154;
      allowed_endpoints = [
        "https://cloud.${config.networking.fqdn}"
        "https://cloud.gopong.dev"
      ];
    };
  };
}
