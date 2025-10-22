{
  withSecrets,
  config,
  ...
}:
withSecrets "pongo" { store = "gopong/picsur.env"; } {
  "picsur".key = "";
}
// {
  services.nginx.virtualHosts."pic.gopong.dev" = {
    forceSSL = true;
    useACMEHost = "gopong.dev";
    locations."/".proxyPass = "http://localhost:11098";
  };

  virtualisation.oci-containers.containers = {
    picsur = {
      image = "ghcr.io/caramelfur/picsur";
      ports = [ "127.0.0.1:11098:8080" ];
      autoStart = true;
      environmentFiles = [ config.sops.secrets."picsur".path ];
      environment = {
        PICSUR_DB_HOST = "host.containers.internal";
        PICSUR_DB_PORT = "11099";
      };
    };

    picsur-postgresql = {
      image = "postgres:17-alpine";
      ports = [ "11099:5432" ];
      autoStart = true;
      environmentFiles = [ config.sops.secrets."picsur".path ];
      environment.POSTGRES_USER = "picsur";
      volumes = [
        "/var/lib/picsur/postgresql:/var/lib/postgresql/data"
      ];
    };
  };
}
