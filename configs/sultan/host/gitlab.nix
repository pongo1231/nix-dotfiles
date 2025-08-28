{
  withSecrets,
  config,
  pkgs,
  ...
}:
withSecrets "pongo"
  {
    store = "sultan.yaml";
    owner = config.services.gitlab.user;
  }
  {
    "gitlab/rootPassword" = { };
    "gitlab/dbPassword" = { };
    "gitlab/secret" = { };
    "gitlab/otpSecret" = { };
    "gitlab/dbSecret" = { };
    "gitlab/activeRecordSalt" = { };
    "gitlab/activeRecordPrimaryKey" = { };
    "gitlab/activeRecordDeterministicKey" = { };
  }
// {
  services = {
    nginx.virtualHosts."git.gopong.dev" = {
      forceSSL = true;
      useACMEHost = "gopong.dev";
      locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
    };

    gitlab = {
      enable = true;
      smtp.enable = true;
      statePath = "/var/lib/gitlab";
      initialRootPasswordFile = config.sops.secrets."gitlab/rootPassword".path;
      databasePasswordFile = config.sops.secrets."gitlab/dbPassword".path;
      secrets = {
        secretFile = config.sops.secrets."gitlab/secret".path;
        otpFile = config.sops.secrets."gitlab/otpSecret".path;
        dbFile = config.sops.secrets."gitlab/dbSecret".path;
        jwsFile = pkgs.runCommand "oidcKeyBase" { } "${pkgs.openssl}/bin/openssl genrsa 2048 > $out";
        activeRecordSaltFile = config.sops.secrets."gitlab/activeRecordSalt".path;
        activeRecordPrimaryKeyFile = config.sops.secrets."gitlab/activeRecordPrimaryKey".path;
        activeRecordDeterministicKeyFile = config.sops.secrets."gitlab/activeRecordDeterministicKey".path;
      };
    };
  };
}
