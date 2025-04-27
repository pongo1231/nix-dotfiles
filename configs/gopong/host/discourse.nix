{
  system,
  inputs,
  withSecrets,
  config,
  ...
}:
withSecrets "pongo"
  {
    store = "gopong";
    owner = config.users.users.discourse.name;
  }
  {
    "discourse/adminPassword" = {
    };
    "discourse/secretKeyBase" = {
    };
  }
// {
  services.discourse = {
    enable = true;
    package = inputs.nixpkgs-stable.legacyPackages.${system}.discourse;
    hostname = "discourse.gopong.dev";
    admin = {
      email = "admin@gopong.dev";
      username = "root";
      fullName = "Root";
      passwordFile = config.sops.secrets."discourse/adminPassword".path;
    };
    secretKeyBaseFile = config.sops.secrets."discourse/secretKeyBase".path;
    database.ignorePostgresqlVersion = true;
    mail = {
      outgoing = {
        serverAddress = "gopong.dev";
        port = 25;
        domain = "gopong.dev";
      };
      notificationEmailAddress = "no-reply@gopong.dev";
    };
  };
}
