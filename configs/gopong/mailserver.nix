{
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.mailserver.nixosModules.default
  ];

  sops.secrets."password_pongo@gopong.dev" = { };

  mailserver = {
    enable = true;
    fqdn = "gopong.dev";
    domains = [ "gopong.dev" ];
    loginAccounts."pongo@gopong.dev" = {
      hashedPasswordFile = config.sops.secrets."password_pongo@gopong.dev".path;
      aliases = [
        "admin@gopong.dev"
        "no-reply@gopong.dev"
      ];
    };
    certificateScheme = "acme";
  };
}
