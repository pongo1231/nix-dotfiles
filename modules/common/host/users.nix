{
  withSecrets,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.pongo.users;
in
{
  options.pongo.users.defaultOverride = lib.mkOption {
    type = lib.types.attrs;
    default = { };
  };

  config =
    withSecrets "pongo" { } {
      "base/userPassword" = {
        neededForUsers = true;
      };
    }
    // {
      programs.fish.enable = true;

      users = {
        mutableUsers = false;
        defaultUserShell = pkgs.fish;

        users.${if cfg.defaultOverride ? name then cfg.defaultOverride.user else "pongo"} = {
          isNormalUser = true;
          hashedPasswordFile = config.sops.secrets."base/userPassword".path;
          linger = true;
          extraGroups = [
            "wheel"
            "input"
            "libvirtd"
            "networkmanager"
            "podman"
            "video"
            "tty"
            "dialout"
            "seat"
            "libvirt"
            "kvm"
            "nginx"
          ];
        } // cfg.defaultOverride;
      };
    };
}
