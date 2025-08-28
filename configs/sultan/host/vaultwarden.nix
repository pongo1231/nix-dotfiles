{
  withSecrets,
  config,
  ...
}:
withSecrets "pongo"
  {
    store = "sultan-vaultwarden.env";
    owner = config.users.users.vaultwarden.name;
  }
  {
    "vaultwarden" = {
      key = "";
    };
  }
// {
  services = {
    nginx.virtualHosts."vault.gopong.dev" = {
      forceSSL = true;
      useACMEHost = "gopong.dev";
      locations."/".proxyPass =
        "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
    };

    vaultwarden = {
      enable = true;
      environmentFile = config.sops.secrets."vaultwarden".path;
      config = {
        DOMAIN = "https://vault.gopong.dev";
        SIGNUPS_ALLOWED = false;
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        SMTP_HOST = "127.0.0.1";
        SMTP_PORT = 25;
        SMTP_SSL = false;
        SMTP_FROM = "no-reply@gopong.dev";
        SMTP_FROM_NAME = "gopong.dev Vaultwarden Server";
      };
    };
  };
}
