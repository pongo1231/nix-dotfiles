{
  inputs,
  configInfo,
  ...
}@args:
{
  imports = [
    inputs.sops-nix.${if configInfo.type == "home" then "homeManagerModules" else "nixosModules"}.sops
  ];

  sops.age = {
    generateKey = true;
  }
  // (
    if configInfo.type == "home" then
      {
        sshKeyPaths = [ "/home/${args.user}/.ssh/id_ed25519" ];
        keyFile = "/home/${args.user}/.age.key";
      }
    else
      {
        sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        keyFile = "/etc/age.key";
      }
  );
}
