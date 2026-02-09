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
    "emails/ec" = { };
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
    domains = [
      config.mailserver.fqdn
      "gopong.dev"
    ];
    mailDirectory = "/var/lib/vmail";
    sieveDirectory = "/var/lib/sieve";
    enableSubmission = true;
    loginAccounts = {
      "pongo@${config.mailserver.fqdn}" = {
        hashedPasswordFile = config.sops.secrets."emails/pongo".path;
        aliases = [
          "@${config.mailserver.fqdn}"
          "@gopong.dev"
        ];
        /*
          catchAll = [
            config.mailserver.fqdn
            "gopong.dev"
          ];
        */
      };

      "ec@${config.mailserver.fqdn}" = {
        hashedPasswordFile = config.sops.secrets."emails/ec".path;
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
