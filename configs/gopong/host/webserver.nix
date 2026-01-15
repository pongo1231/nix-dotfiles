{ config, ... }:
{
  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;

    virtualHosts = {
      "_" = {
        rejectSSL = true;
        globalRedirect = config.networking.fqdn;
      };

      "${config.networking.fqdn}" = {
        forceSSL = true;
        useACMEHost = config.networking.fqdn;
        root = "/srv/http";
      };

      "chaos.${config.networking.fqdn}" = {
        forceSSL = true;
        useACMEHost = config.networking.fqdn;
        locations."/".proxyPass = "http://localhost:9907";
        extraConfig = ''
          client_max_body_size 50M;
        '';
      };

      "hotel.${config.networking.fqdn}" = {
        forceSSL = true;
        useACMEHost = config.networking.fqdn;
        locations."/".proxyPass = "http://localhost:8081";
      };

      "fastdl.${config.networking.fqdn}" = {
        addSSL = true;
        useACMEHost = config.networking.fqdn;
        root = "/srv/http/fastdl";
        extraConfig = ''
          autoindex on;
          sub_filter '</body>' '<div class="footer">FastDL server for DuckyServers.<br>Also available for public use.<br>sv_downloadurl "http://fastdl.gopong.dev/game/"</div></body>';
        '';
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "pongo@${config.mailserver.fqdn}";
      webroot = "/var/lib/acme/acme-challenge";
    };
    certs."${config.networking.fqdn}" = {
      group = "nginx";
      extraDomainNames = [
        "chaos.${config.networking.fqdn}"
        "hotel.${config.networking.fqdn}"
        "cloud.${config.networking.fqdn}"
        "fastdl.${config.networking.fqdn}"
        "vault.${config.networking.fqdn}"
        "collabora.${config.networking.fqdn}"
        "git.${config.networking.fqdn}"
        "paste.${config.networking.fqdn}"
        "pic.${config.networking.fqdn}"
        "fmd.${config.networking.fqdn}"
        "molly.${config.networking.fqdn}"
      ];
    };
  };

}
