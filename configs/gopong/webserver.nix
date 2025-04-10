{ ... }:
{
  services = {
    nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      recommendedProxySettings = true;
      recommendedGzipSettings = true;
      virtualHosts = {
        "_" = {
          rejectSSL = true;
          globalRedirect = "gopong.dev";
        };

        "gopong.dev" = {
          forceSSL = true;
          enableACME = true;
          root = "/srv/http";
        };

        "tf.gopong.dev" = {
          rejectSSL = true;
          extraConfig = ''
            autoindex on;
          '';
          root = "/srv/http/tf";
        };

        "chaos.gopong.dev" = {
          forceSSL = true;
          enableACME = true;
          locations."/".proxyPass = "https://gopong.dev:9907";
          extraConfig = ''
            client_max_body_size 50M;
          '';
        };

        "habbo.gopong.dev" = {
          forceSSL = true;
          enableACME = true;
          locations."/".proxyPass = "https://gopong.dev:8081";
        };
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "pongo1999712@gmail.com";
  };
}
