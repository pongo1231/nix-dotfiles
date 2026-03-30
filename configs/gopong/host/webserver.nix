{
  config,
  lib,
  ...
}:
let
  cfg = config.gopong;
  domains = [
    config.networking.fqdn
    "gopong.dev"
  ];
in
{
  options = {
    gopong.virtualHosts = lib.mkOption {
      type = lib.types.attrs;
      default = [ ];
    };
  };

  config = {
    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      recommendedProxySettings = true;
      recommendedGzipSettings = true;

      virtualHosts =
        let
          root = "/var/lib/www";
        in
        {
          "_" = {
            rejectSSL = true;
            globalRedirect = config.networking.fqdn;
          };
        }
        // lib.foldl' (
          acc: domain:
          acc
          //
            lib.mapAttrs'
              (name: val: {
                name = "${name}${if name == "" then "" else "."}${domain}";
                value = {
                  forceSSL = true;
                  useACMEHost = domain;
                }
                // val;
              })
              (
                cfg.virtualHosts
                // {
                  "" = {
                    inherit root;
                  };

                  "chaos" = {
                    locations."/".proxyPass = "http://localhost:9907";
                    extraConfig = ''
                      client_max_body_size 50M;
                    '';
                  };

                  "hotel".locations."/".proxyPass = "http://localhost:8081";

                  "fastdl" = {
                    forceSSL = false;
                    addSSL = true;
                    root = "${root}/fastdl";
                    extraConfig = ''
                      autoindex on;
                      sub_filter '</body>' '<div class="footer">FastDL server for DuckyServers.<br>Also available for public use.<br>sv_downloadurl "http://fastdl.${config.networking.fqdn}/game/"</div></body>';
                    '';
                  };

                  "servers".locations = {
                    "/".proxyPass = "http://localhost:8999";
                    "/ws" = {
                      proxyPass = "http://localhost:8999";
                      proxyWebsockets = true;
                    };
                  };
                }
              )
        ) { } domains;
    };
    security.acme = {
      acceptTerms = true;
      defaults = {
        email = "admin@${config.mailserver.fqdn}";
        webroot = "/var/lib/acme/acme-challenge";
      };
      certs = lib.genAttrs domains (domain: {
        group = "nginx";
        extraDomainNames = [
          "chaos.${domain}"
          "hotel.${domain}"
          "cloud.${domain}"
          "fastdl.${domain}"
          "vault.${domain}"
          "collabora.${domain}"
          "git.${domain}"
          "paste.${domain}"
          "pic.${domain}"
          "fmd.${domain}"
          "molly.${domain}"
          "karakeep.${domain}"
          "firefox-syncserver.${domain}"
          "servers.${domain}"
        ];
      });
    };
  };
}
