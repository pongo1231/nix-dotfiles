{
  withSecrets,
  config,
  pkgs,
  ...
}:
withSecrets "pongo"
  {
    store = "gopong/default.yaml";
    owner = config.services.gitlab.user;
  }
  {
    "gitlab/rootPassword" = { };
    "gitlab/emailPassword" = { };
    "gitlab/dbPassword" = { };
    "gitlab/secret" = { };
    "gitlab/otpSecret" = { };
    "gitlab/dbSecret" = { };
    "gitlab/activeRecordSalt" = { };
    "gitlab/activeRecordPrimaryKey" = { };
    "gitlab/activeRecordDeterministicKey" = { };
  }
// {
  gopong.virtualHosts."git".locations."/".proxyPass =
    "http://unix:/run/gitlab/gitlab-workhorse.socket";

  services.gitlab = {
    enable = true;
    host = "git.${config.networking.fqdn}";

    statePath = "/var/lib/gitlab";
    initialRootPasswordFile = config.sops.secrets."gitlab/rootPassword".path;
    databasePasswordFile = config.sops.secrets."gitlab/dbPassword".path;
    initialRootEmail = "admin@${config.mailserver.fqdn}";

    secrets = {
      secretFile = config.sops.secrets."gitlab/secret".path;
      otpFile = config.sops.secrets."gitlab/otpSecret".path;
      dbFile = config.sops.secrets."gitlab/dbSecret".path;
      jwsFile = pkgs.runCommand "oidcKeyBase" { } "${pkgs.openssl}/bin/openssl genrsa 2048 > $out";
      activeRecordSaltFile = config.sops.secrets."gitlab/activeRecordSalt".path;
      activeRecordPrimaryKeyFile = config.sops.secrets."gitlab/activeRecordPrimaryKey".path;
      activeRecordDeterministicKeyFile = config.sops.secrets."gitlab/activeRecordDeterministicKey".path;
    };

    smtp = {
      enable = true;
      domain = "${config.mailserver.fqdn}";
      port = 465;
      address = "${config.mailserver.fqdn}";
      username = "no-reply@${config.mailserver.fqdn}";
      passwordFile = config.sops.secrets."gitlab/emailPassword".path;
      tls = true;
      enableStartTLSAuto = false;
    };

    extraConfig = {
      "gitlab" = {
        "email_from" = "no-reply@${config.mailserver.fqdn}";
        "email_reply_to" = "no-reply@${config.mailserver.fqdn}";
      };
    };
  };
}
