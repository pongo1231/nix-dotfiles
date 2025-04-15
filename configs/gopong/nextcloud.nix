{
  patch,
  withSecrets,
  pkgs,
  config,
  ...
}:
withSecrets "pongo" { owner = config.users.users.nextcloud.name; } {
  "nextcloud/adminPassword" = { };
}
// {
  services = {
    nginx.virtualHosts."cloud.gopong.dev" = {
      forceSSL = true;
      enableACME = true;
    };

    nextcloud = {
      enable = true;
      package = pkgs.nextcloud31.overrideAttrs (
        finalAttrs: prevAttrs: {
          patches = (prevAttrs.patches or [ ]) ++ [
            (patch /nextcloud/44574.patch)
          ];
        }
      );
      hostName = "cloud.gopong.dev";
      https = true;
      config = {
        adminpassFile = config.sops.secrets."nextcloud/adminPassword".path;
        dbtype = "pgsql";
      };
    };
  };

  environment.systemPackages = with pkgs; [ ffmpeg ];
}
