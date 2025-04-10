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
    loginAccounts."stuff" = {
      hashedPassword = "$y$j9T$c2Nt1td.mLWHzJt2GuFhG.$.QLj0Uh94KxKKq15MKXG6EUNJRt9N/AH7cSf2ABsQZ5";
      aliases = [ "no-reply@gopong.dev" ];
    };
    certificateScheme = "acme";
  };
}
