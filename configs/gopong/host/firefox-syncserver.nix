{
  withSecrets,
  config,
  pkgs,
  lib,
  ...
}:
withSecrets "pongo" { store = "gopong/firefox-syncserver.env"; } {
  "firefox-syncserver".key = "";
}
// {
  services = {
    nginx.virtualHosts."firefox-syncserver.${config.networking.fqdn}" = {
      forceSSL = true;
      useACMEHost = config.networking.fqdn;
      locations."/".proxyPass =
        "http://localhost:${toString config.services.firefox-syncserver.settings.port}";
    };

    mysql = {
      package = pkgs.mariadb;
      settings.mysqld.port = 3307;
    };

    firefox-syncserver = {
      enable = true;
      secrets = config.sops.secrets."firefox-syncserver".path;
      database.type = "mysql";
      singleNode = {
        enable = true;
        hostname = "firefox-syncserver.${config.networking.fqdn}";
      };
    };
  };

  systemd.services."firefox-syncserver".serviceConfig.DynamicUser = lib.mkForce false;

  users = {
    groups."firefox-syncserver" = { };
    users."firefox-syncserver" = {
      group = "firefox-syncserver";
      isSystemUser = true;
    };
  };
}
