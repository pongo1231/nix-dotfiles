{
  withSecrets,
  inputs,
  config,
  pkgs,
  ...
}:
withSecrets "pongo"
  {
    store = "gopong/default.yaml";
    owner = config.users.users.discourse.name;
  }
  {
    "discourse/adminPassword" = { };
    "discourse/emailPassword" = { };
    "discourse/secretKeyBase" = { };
  }
// {
  services.discourse = {
    enable = true;
    package = inputs.nixpkgs3.legacyPackages.${pkgs.stdenv.hostPlatform.system}.discourse;
    hostname = "discourse.${config.networking.fqdn}";
    admin = {
      email = "admin@${config.mailserver.fqdn}";
      username = "root";
      fullName = "Root";
      passwordFile = config.sops.secrets."discourse/adminPassword".path;
    };
    secretKeyBaseFile = config.sops.secrets."discourse/secretKeyBase".path;
    database.ignorePostgresqlVersion = true;
    mail.outgoing = {
      serverAddress = config.mailserver.fqdn;
      domain = config.mailserver.fqdn;
      username = "no-reply@${config.mailserver.fqdn}";
      passwordFile = config.sops.secrets."discourse/emailPassword".path;
    };
  };
}
