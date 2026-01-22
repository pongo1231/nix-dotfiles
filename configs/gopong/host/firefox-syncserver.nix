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
      package = pkgs.syncstorage-rs.overrideAttrs (
        let
          src = pkgs.fetchFromGitHub {
            owner = "mozilla-services";
            repo = "syncstorage-rs";
            rev = "6af6d5c6b6b58edc5eb272926000ec93dbb7f2e1";
            hash = "sha256-1rdsa5OJYxE69EVd+3JI8DsSSbJDAelBfTgHhQJzR+0=";
          };
        in
        {
          inherit src;

          cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
            inherit src;
            hash = "sha256-9Dcf5mDyK/XjsKTlCPXTHoBkIq+FFPDg1zfK24Y9nHQ=";
          };
        }
      );

      secrets = config.sops.secrets."firefox-syncserver".path;
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
