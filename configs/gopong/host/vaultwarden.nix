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
    "vaultwarden".key = "";
  }
// {
  gopong.virtualHosts."vault".locations."/".proxyPass =
    "http://localhost:${toString config.services.vaultwarden.config.ROCKET_PORT}";

  services.vaultwarden = {
    enable = true;
    environmentFile = config.sops.secrets."vaultwarden".path;
    config = {
      DOMAIN = "https://vault.${config.networking.fqdn}";
      SIGNUPS_ALLOWED = false;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      SMTP_HOST = config.mailserver.fqdn;
      SMTP_PORT = 465;
      SMTP_SECURITY = "force_tls";
      SMTP_USERNAME = "no-reply@${config.mailserver.fqdn}";
      SMTP_FROM = "no-reply@${config.mailserver.fqdn}";
    };
  };
}
