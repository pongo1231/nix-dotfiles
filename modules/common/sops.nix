{
  inputs,
  secret,
  private,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = "${secret "pongo" /secrets.yaml}";
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/etc/nixos/private/age.key";
      generateKey = true;
    };
  };
}
