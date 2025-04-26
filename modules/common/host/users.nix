{
  withSecrets,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.pongo;
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

        users.${if cfg.users.defaultOverride ? name then cfg.users.defaultOverride.user else "pongo"} = {
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
        } // cfg.users.defaultOverride;
      };
    };
}
