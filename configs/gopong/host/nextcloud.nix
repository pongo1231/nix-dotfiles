{
  withSecrets,
  config,
  pkgs,
  lib,
  ...
}:
lib.mkMerge [
  (withSecrets "pongo"
    {
      store = "gopong/default.yaml";
      owner = config.users.users.nextcloud.name;
    }
    {
      "nextcloud/adminPassword" = { };
    }
  )

  (withSecrets "pongo"
    {
      store = "gopong/nextcloud.json";
      owner = config.users.users.nextcloud.name;
    }
    {
      "nextcloudfile".key = "";
    }
  )

  {
    services = {
      nginx.virtualHosts = {
        "cloud.${config.networking.fqdn}" = {
          forceSSL = true;
          useACMEHost = config.networking.fqdn;
        };

        "collabora.${config.networking.fqdn}" = {
          forceSSL = true;
          useACMEHost = config.networking.fqdn;
          locations."/" = {
            proxyPass = "https://localhost:9980";
            proxyWebsockets = true;
          };
        };
      };

      nextcloud = {
        enable = true;
        package = pkgs.nextcloud32;
        hostName = "cloud.${config.networking.fqdn}";
        https = true;

        config = {
          adminpassFile = config.sops.secrets."nextcloud/adminPassword".path;
          dbtype = "pgsql";
        };

        caching = {
          apcu = false;
          redis = true;
          memcached = false;
        };

        settings = {
          "mail_domain" = "${config.mailserver.fqdn}";
          "mail_from_address" = "no-reply";
          "mail_smtphost" = "${config.mailserver.fqdn}";
          "mail_smtpport" = 465;
          "mail_smtpauth" = true;
          "mail_smtpname" = "no-reply@gopong.dev";
          "mail_smtpsecure" = "ssl";
        };

        secretFile = config.sops.secrets."nextcloudfile".path;
      };
    };

    virtualisation.oci-containers.containers.collabora = {
      image = "docker.io/collabora/code";
      ports = [ "9980:9980" ];
      autoStart = true;
      environment.aliasgroup1 = "https://${config.services.nextcloud.hostName}:443";
    };

    environment.systemPackages = with pkgs; [ ffmpeg ];
  }
]
