{
  withSecrets,
  config,
  ...
}:
withSecrets "pongo" { store = "sultan/findmydevice.env"; } {
  "findmydevice".key = "";
}
// {
  services.nginx.virtualHosts."fmd.gopong.dev" = {
    forceSSL = true;
    useACMEHost = "gopong.dev";
    locations."/".proxyPass = "http://localhost:27091";
  };

  virtualisation.oci-containers.containers.fmd = {
    image = "registry.gitlab.com/fmd-foss/fmd-server:v0.11.0";
    ports = [ "127.0.0.1:27091:8080" ];
    autoStart = true;
    volumes = [ "/var/lib/fmd-server/db:/var/lib/fmd-server/db" ];
    environmentFiles = [ config.sops.secrets."findmydevice".path ];
  };
}
