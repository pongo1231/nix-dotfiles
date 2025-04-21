{
  inputs,
  withSecrets,
  config,
  ...
}:
withSecrets "pongo" { owner = config.users.users.postfix.name; } { "base/emailPassword" = { }; }
// {
  imports = [
    inputs.mailserver.nixosModules.default
  ];

  mailserver = {
    enable = true;
    fqdn = "gopong.dev";
    domains = [ "gopong.dev" ];
    loginAccounts."pongo@gopong.dev" = {
      hashedPasswordFile = config.sops.secrets."base/emailPassword".path;
      aliases = [
        "admin@gopong.dev"
        "no-reply@gopong.dev"
      ];
    };
    certificateScheme = "acme";
  };
}
