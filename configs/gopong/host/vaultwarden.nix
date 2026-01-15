{
  withSecrets,
  config,
  ...
}:
withSecrets "pongo"
  {
    store = "gopong/vaultwarden.env";
    owner = config.users.users.vaultwarden.name;
  }
  {
    "vaultwarden" = {
      key = "";
    };
  }
// {
  services = {
    nginx.virtualHosts."vault.${config.networking.fqdn}" = {
      forceSSL = true;
      useACMEHost = config.networking.fqdn;
      locations."/".proxyPass =
        "http://localhost:${toString config.services.vaultwarden.config.ROCKET_PORT}";
    };

    vaultwarden = {
      enable = true;
      environmentFile = config.sops.secrets."vaultwarden".path;
      config = {
        DOMAIN = "https://vault.${config.networking.fqdn}";
        SIGNUPS_ALLOWED = false;
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        SMTP_HOST = "127.0.0.1";
        SMTP_PORT = 25;
        SMTP_SSL = false;
        SMTP_FROM = "no-reply@${config.mailserver.fqdn}";
        SMTP_FROM_NAME = "${config.networking.fqdn} Vaultwarden Server";
      };
    };
  };
}
