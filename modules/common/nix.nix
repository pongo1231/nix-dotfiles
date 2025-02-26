{ useLixModule }:
{
  system,
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = lib.optionals (useLixModule) [
    inputs.lix.nixosModules.default
  ];

  nix =
    lib.optionalAttrs (!useLixModule) {
      package = lib.mkDefault pkgs.lix;
    }
    // {
      extraOptions = ''
        experimental-features = ca-derivations nix-command flakes recursive-nix
        keep-outputs = true
        keep-derivations = true
      '';

      nixPath = [
        "/etc/nix/inputs"
      ];

      daemonCPUSchedPolicy = "idle";
      daemonIOSchedClass = "idle";

      settings = {
        auto-optimise-store = true;
        trusted-users = [
          "root"
          "@wheel"
        ];
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://pongo1231.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "pongo1231.cachix.org-1:3B6q/T1NL/YPokIFY4lthjoI6vCMKiuYjTGY3gJtZPg="
        ];
        extra-sandbox-paths = [ config.programs.ccache.cacheDir ];
      };

      registry = lib.mapAttrs' (name: flake: {
        inherit name;
        value.flake = flake;
      }) inputs;
    };

  nixpkgs = {
    hostPlatform.system = system;
    #buildPlatform.system = "x86_64-linux";
    config.allowUnfree = true;
  };
}
