{
  pkgs,
  ...
}:
{
  services = {
    nginx.virtualHosts."cloud.gopong.dev" = {
      forceSSL = true;
      enableACME = true;
    };

    nextcloud = {
      enable = true;
      package = pkgs.nextcloud31;
      hostName = "cloud.gopong.dev";
      https = true;
      config = {
        adminpassFile = "/etc/nextcloud-admin-pass";
        dbtype = "sqlite";
      };
    };
  };
}
