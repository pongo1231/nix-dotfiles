{
  withSecrets,
  config,
  pkgs,
  ...
}:
withSecrets "pongo"
  {
    store = "sultan.yaml";
    owner = config.users.users.nextcloud.name;
  }
  {
    "nextcloud/adminPassword" = { };
  }
// {
  services = {
    nginx.virtualHosts = {
      "cloud.gopong.dev" = {
        forceSSL = true;
        useACMEHost = "gopong.dev";
      };

      "collabora.gopong.dev" = {
        forceSSL = true;
        useACMEHost = "gopong.dev";
        locations."/" = {
          proxyPass = "https://gopong.dev:9980";
          proxyWebsockets = true;
        };
      };
    };

    redis.servers."nextcloud" = {
      enable = true;
      port = 6501;
    };

    nextcloud = {
      enable = true;
      package = pkgs.nextcloud31;
      hostName = "cloud.gopong.dev";
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
    };
  };

  virtualisation.oci-containers.containers.collabora = {
    image = "docker.io/collabora/code";
    ports = [ "9980:9980" ];
    autoStart = true;
    environment.aliasgroup1 = "https://${config.services.nextcloud.hostName}:443";
  };

  environment.systemPackages = with pkgs; [ ffmpeg ];

  system.activationScripts.nextcloud-config.text =
    let
      occ = "${config.services.nextcloud.occ}/bin/nextcloud-occ";
    in
    ''
      ${occ} config:system:set redis 'host' --value 'localhost' --type string
      ${occ} config:system:set redis 'port' --value ${
        builtins.toString config.services.redis.servers."nextcloud".port
      } --type integer
      ${occ} config:system:set memcache.local --value '\OC\Memcache\Redis' --type string
      ${occ} config:system:set memcache.locking --value '\OC\Memcache\Redis' --type string
    '';
}
