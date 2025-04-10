{
  system,
  inputs,
  ...
}:
{
  services.discourse = {
    enable = true;
    package = inputs.nixpkgs-stable.legacyPackages.${system}.discourse;
    hostname = "discourse.gopong.dev";
    admin = {
      email = "admin@gopong.dev";
      username = "root";
      fullName = "Root";
      passwordFile = "/etc/discourse-admin-pass";
    };
    secretKeyBaseFile = "/etc/discourse-secret-key-base";
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
