{
  withSecrets,
  config,
  pkgs,
  ...
}:
withSecrets "pongo"
  {
    store = "sultan";
    owner = config.users.users.nextcloud.name;
  }
  {
    "nextcloud/adminPassword" = { };
  }
// {
  services = {
    nginx.virtualHosts."cloud.gopong.dev" = {
      forceSSL = true;
      useACMEHost = "gopong.dev";
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
