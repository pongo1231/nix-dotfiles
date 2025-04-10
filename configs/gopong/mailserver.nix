{
  inputs,
  services,
  ...
}:
{
  imports = [
    inputs.mailserver.nixosModules.default
  ];

  mailserver = {
    enable = true;
    fqdn = "gopong.dev";
    domains = [ "gopong.dev" ];
    loginAccounts."pongo@gopong.dev" = {
      hashedPassword = "$y$j9T$jdjb8HAW.L3Hgtoj836Ez1$Vd.WqCTC0QmWYU4K4yCUBkdxxuxyJ4AKzVCN5vrlqh3";
      aliases = [
        "admin@gopong.dev"
        "no-reply@gopong.dev"
      ];
    };
    certificateScheme = "acme";
  };
}
