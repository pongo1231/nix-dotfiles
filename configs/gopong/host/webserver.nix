_: {
  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    recommendedGzipSettings = true;

    virtualHosts."tf.gopong.dev" = {
      rejectSSL = true;
      extraConfig = ''
        autoindex on;
      '';
      root = "/srv/http/tf";
    };
  };
}
