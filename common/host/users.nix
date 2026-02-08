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

        users = {
          root.hashedPasswordFile = config.sops.secrets."base/userPassword".path;

          "${if cfg.defaultOverride ? name then cfg.defaultOverride.user else "pongo"}" = {
            isNormalUser = true;
            uid = 1000;
            hashedPasswordFile = config.sops.secrets."base/userPassword".path;
            linger = true;
            extraGroups = [
              "wheel"
              "libvirtd"
              "networkmanager"
              "seat"
              "libvirt"
              "kvm"
              "nginx"
            ];
          }
          // cfg.defaultOverride;
        };
      };

      environment.etc =
        let
          autosubs =
            let
              cfg = config.users.users;
            in
            lib.pipe cfg [
              lib.attrNames
              (lib.filter (x: cfg."${x}".isNormalUser))
              (lib.concatMapStrings (x: "${x}:${toString (100000 + (cfg.${x}.uid - 1000) * 65536)}:65536\n"))
            ];
        in
        {
          "subuid".text = autosubs;
          "subuid".mode = "0444";
          "subgid".text = autosubs;
          "subgid".mode = "0444";
        };
    };
}
