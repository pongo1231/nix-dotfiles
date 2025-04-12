{ defaultUserOverride }:
{
  config,
  pkgs,
  ...
}:
{
  sops.secrets.password_pongo.neededForUsers = true;

  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.fish;

    users.${if (defaultUserOverride ? name) then defaultUserOverride.user else "pongo"} = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.password_pongo.path;
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
    } // defaultUserOverride;
  };
}
