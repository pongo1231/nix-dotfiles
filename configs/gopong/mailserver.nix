{
  inputs,
  withSecret,
  config,
  ...
}:
withSecret "pongo" "password_pongo@gopong.dev" { }
// {
  imports = [
    inputs.mailserver.nixosModules.default
  ];

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
