{
  inputs,
  configInfo,
  ...
}:
{
  imports = [
    inputs.sops-nix.${if configInfo.type == "home" then "homeManagerModules" else "nixosModules"}.sops
  ];

  sops.age = {
    sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    keyFile = "/etc/nixos/private/age.key";
    generateKey = true;
  };
}
