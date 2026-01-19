{
  withSecrets,
  config,
  ...
}:
withSecrets "pongo"
  {
    store = "gopong/karakeep.env";
    owner = "karakeep";
  }
  {
    "karakeep".key = "";
  }
// {
  services = {
    nginx.virtualHosts."karakeep.${config.networking.fqdn}" = {
      forceSSL = true;
      useACMEHost = config.networking.fqdn;
      locations."/".proxyPass = "http://localhost:${config.services.karakeep.extraEnvironment.PORT}";
    };

    karakeep = {
      enable = true;
      environmentFile = config.sops.secrets."karakeep".path;
      extraEnvironment = {
        PORT = "3817";
        DISABLE_SIGNUPS = "true";
        EMAIL_VERIFICATION_REQUIRED = "true";
        SMTP_HOST = config.mailserver.fqdn;
        SMTP_FROM = "no-reply@${config.mailserver.fqdn}";
        NEXTAUTH_URL = "https://karakeep.${config.networking.fqdn}";
      };
    };
  };
}
