{
  inputs,
  withSecrets,
  config,
  pkgs,
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
  gopong.virtualHosts."karakeep".locations."/".proxyPass =
    "http://localhost:${config.services.karakeep.extraEnvironment.PORT}";

  services.karakeep = {
    enable = true;
    package = inputs.nixpkgs2.legacyPackages.${pkgs.stdenv.hostPlatform.system}.karakeep;
    environmentFile = config.sops.secrets."karakeep".path;
    extraEnvironment = {
      PORT = "3817";
      DISABLE_SIGNUPS = "true";
      EMAIL_VERIFICATION_REQUIRED = "true";
      SMTP_HOST = config.mailserver.fqdn;
      SMTP_USER = "no-reply@${config.mailserver.fqdn}";
      SMTP_FROM = "no-reply@${config.mailserver.fqdn}";
      NEXTAUTH_URL = "https://karakeep.${config.networking.fqdn}";
    };
  };
}
