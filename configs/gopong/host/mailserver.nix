{
  inputs,
  withSecrets,
  config,
  ...
}:
withSecrets "pongo"
  {
    store = "gopong/default.yaml";
    owner = config.users.users.postfix.name;
  }
  {
    "emails/pongo" = { };
    "emails/chaos" = { };
  }
// {
  imports = [
    inputs.mailserver.nixosModules.default
  ];

  mailserver = {
    enable = true;
    stateVersion = 3;
    fqdn = "gopong.dev";
    domains = [ "gopong.dev" ];
    mailDirectory = "/var/lib/vmail";
    sieveDirectory = "/var/lib/sieve";
    certificateDirectory = "/var/lib/certs";
    loginAccounts = {
      "pongo@gopong.dev" = {
        hashedPasswordFile = config.sops.secrets."emails/pongo".path;
        aliases = [
          "admin@gopong.dev"
          "no-reply@gopong.dev"
        ];
      };

      "chaos@gopong.dev" = {
        hashedPasswordFile = config.sops.secrets."emails/chaos".path;
      };
    };
    certificateScheme = "acme";
  };
}
