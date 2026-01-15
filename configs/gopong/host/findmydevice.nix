{
  withSecrets,
  config,
  ...
}:
withSecrets "pongo" { store = "gopong/findmydevice.env"; } {
  "findmydevice".key = "";
}
// {
  services.nginx.virtualHosts."fmd.${config.networking.fqdn}" = {
    forceSSL = true;
    useACMEHost = config.networking.fqdn;
    locations."/".proxyPass = "http://localhost:27091";
  };

  virtualisation.oci-containers.containers.fmd = {
    image = "registry.gitlab.com/fmd-foss/fmd-server:0-distroless";
    ports = [ "127.0.0.1:27091:8080" ];
    autoStart = true;
    volumes = [ "/var/lib/fmd-server/db:/var/lib/fmd-server/db" ];
    environmentFiles = [ config.sops.secrets."findmydevice".path ];
  };
}
