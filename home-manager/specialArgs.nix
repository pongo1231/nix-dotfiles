{ system, inputs, ... }@args:
{
  module = file: ./modules/${file};
  patch = file: ./patches/${file};
  pkg = file: ./pkgs/${file};
  withSecret = user: secret: options: {
    sops.secrets.${secret} = {
      sopsFile = ./secrets/${user}/secrets.yaml;
    } // options;
  };
  private = file: ./private/${file};
}
// args
