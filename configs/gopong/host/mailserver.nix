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
    "emails/no-reply" = { };
    "emails/chaos" = { };
  }
// {
  imports = [
    inputs.mailserver.nixosModules.default
  ];

  mailserver = {
    enable = true;
    stateVersion = 3;
    inherit (config.networking) fqdn;
    domains = [ config.mailserver.fqdn ];
    mailDirectory = "/var/lib/vmail";
    sieveDirectory = "/var/lib/sieve";
    enableSubmission = true;
    loginAccounts = {
      "pongo@${config.mailserver.fqdn}" = {
        hashedPasswordFile = config.sops.secrets."emails/pongo".path;
        aliases = [ "admin@${config.mailserver.fqdn}" ];
        catchAll = [ config.mailserver.fqdn ];
      };

      "no-reply@${config.mailserver.fqdn}" = {
        hashedPasswordFile = config.sops.secrets."emails/no-reply".path;
      };

      "chaos@${config.mailserver.fqdn}" = {
        hashedPasswordFile = config.sops.secrets."emails/chaos".path;
      };
    };

    x509.useACMEHost = config.mailserver.fqdn;
  };
}
