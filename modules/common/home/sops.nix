{
  inputs,
  secret,
  private,
  ...
}:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    age.keyFile = private /age.key;
    defaultSopsFile = secret /secrets.yaml;
  };
}
