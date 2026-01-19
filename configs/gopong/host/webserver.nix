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
      email = "admin@${config.mailserver.fqdn}";
      webroot = "/var/lib/acme/acme-challenge";
    };
    certs."${config.networking.fqdn}" = {
      group = "nginx";
      extraDomainNames =
        let
          fqdn = config.networking.fqdn;
        in
        [
          "chaos.${fqdn}"
          "hotel.${fqdn}"
          "cloud.${fqdn}"
          "fastdl.${fqdn}"
          "vault.${fqdn}"
          "collabora.${fqdn}"
          "git.${fqdn}"
          "paste.${fqdn}"
          "pic.${fqdn}"
          "fmd.${fqdn}"
          "molly.${fqdn}"
          "karakeep.${fqdn}"
        ];
    };
  };

}
