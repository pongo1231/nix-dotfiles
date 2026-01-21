{
  inputs,
  configInfo,
  config,
  pkgs,
  lib,
  ...
}:
{
  nix = {
    nixPath =
      if configInfo.type != "host" then
        [ "${config.xdg.configHome}/nix/inputs" ]
      else
        [ "/etc/nix/inputs" ];

    registry = lib.mapAttrs' (name: flake: {
      inherit name;
      value.flake = flake;
    }) inputs;

    extraOptions = ''
      experimental-features = nix-command flakes ${
        lib.optionalString (configInfo.type == "host") "auto-allocate-uids cgroups"
      }
    ''
    + lib.optionalString (configInfo.type == "host") ''
      auto-allocate-uids = true
      use-cgroups = true
    '';

    settings = lib.optionalAttrs (configInfo.type == "host") {
      auto-optimise-store = true;
      allowed-users = [ "@users" ];
      trusted-users = [ "@wheel" ];
    };
  }
  // lib.optionalAttrs (configInfo.type == "host") {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
  }
  // lib.optionalAttrs (configInfo.type == "host" || !configInfo.isNixosModule) {
    package = pkgs.lixPackageSets.latest.lix;
  };

  nixpkgs = lib.optionalAttrs (configInfo.type == "host" || !configInfo.isNixosModule) {
    config = {
      allowUnfree = true;
      nvidia.acceptLicense = true;
    };
  };
}
// lib.optionalAttrs (configInfo.type == "host") {
  fileSystems."/nix/var/nix/b" = {
    fsType = "tmpfs";
    options = [
      "noatime"
      "lazytime"
      "mode=0755"
      "size=100G"
      "huge=within_size"
    ];
  };
}
