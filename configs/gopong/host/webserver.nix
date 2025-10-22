_: {
  services.nginx = {
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
        useACMEHost = "gopong.dev";
        root = "/srv/http";
      };

      "chaos.gopong.dev" = {
        forceSSL = true;
        useACMEHost = "gopong.dev";
        locations."/".proxyPass = "https://gopong.dev:9907";
        extraConfig = ''
          client_max_body_size 50M;
        '';
      };

      "habbo.gopong.dev" = {
        forceSSL = true;
        useACMEHost = "gopong.dev";
        locations."/".proxyPass = "https://gopong.dev:8081";
      };
    };

    virtualHosts."tf.gopong.dev" = {
      rejectSSL = true;
      extraConfig = ''
        autoindex on;
      '';
      root = "/srv/http/tf";
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "pongo@gopong.dev";
      webroot = "/var/lib/acme/acme-challenge";
    };
    certs."gopong.dev" = {
      group = "nginx";
      extraDomainNames = [
        "chaos.gopong.dev"
        "habbo.gopong.dev"
        "cloud.gopong.dev"
        "vault.gopong.dev"
        "collabora.gopong.dev"
        "git.gopong.dev"
        "paste.gopong.dev"
        "pic.gopong.dev"
        "fmd.gopong.dev"
        "molly.gopong.dev"
      ];
    };
  };

}
