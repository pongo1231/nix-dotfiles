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

    registry =
      (lib.mapAttrs' (name: flake: {
        inherit name;
        value.flake = flake;
      }) inputs)
      // {
        microvm.to = {
          owner = "microvm-nix";
          repo = "microvm.nix";
          type = "github";
        };

        nix-direnv.to = {
          owner = "nix-community";
          repo = "nix-direnv";
          type = "github";
        };
      };

    extraOptions = ''
      experimental-features = nix-command flakes
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
      permittedInsecurePackages = [ "python-2.7.18.12" ];
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
