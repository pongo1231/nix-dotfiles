{
  patch,
  pkgs,
  ...
}:
{
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
        adminpassFile = "/etc/nextcloud-admin-pass";
        dbtype = "pgsql";
      };
    };
  };

  environment.systemPackages = with pkgs; [ ffmpeg ];
}
