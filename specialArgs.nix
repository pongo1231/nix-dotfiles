{
  system,
  inputs,
  lib,
  ...
}@args:
{
  module = file: ./modules/${file};
  patch = file: ./patches/${file};
  pkg = file: ./pkgs/${file};

  withSecrets =
    user:
    {
      owner ? null,
      group ? null,
    }:
    secrets: {
      sops.secrets = lib.mapAttrs' (name: value: {
        inherit name;
        value =
          {
            sopsFile = ./secrets/${user}/secrets.yaml;
          }
          // lib.optionalAttrs (owner != null) { inherit owner; }
          // lib.optionalAttrs (group != null) {
            inherit group;
            mode = "0440";
          }
          // value;
      }) secrets;
    };

  private = file: ./private/${file};
}
// builtins.removeAttrs args [ "lib" ]
