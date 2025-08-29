{
  withSecrets,
  config,
  pkgs,
  ...
}:
withSecrets "pongo"
  {
    store = "sultan/default.yaml";
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
    package = pkgs.discourse;
    hostname = "discourse.gopong.dev";
    admin = {
      email = "admin@gopong.dev";
      username = "root";
      fullName = "Root";
      passwordFile = config.sops.secrets."discourse/adminPassword".path;
    };
    secretKeyBaseFile = config.sops.secrets."discourse/secretKeyBase".path;
    database.ignorePostgresqlVersion = true;
    mail.outgoing = {
      serverAddress = "gopong.dev";
      domain = "gopong.dev";
      username = "pongo@gopong.dev";
      passwordFile = config.sops.secrets."discourse/emailPassword".path;
    };
  };
}
