args:
{
  inputs,
  user,
  module,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.nix-index-database.homeModules.nix-index

    ../nix.nix
    ../overlay.nix
    ../sops.nix

    ./helpers.nix
    #./suspender.nix
    ./micro.nix
    ./replaceDependencies.nix
  ];

  pongo = args;

  home = {
    username = user;
    homeDirectory = "/home/${user}";
  };

  programs = {
    fzf = {
      enable = true;
      enableFishIntegration = true;
      tmux.enableShellIntegration = true;
    };

    git = {
      enable = true;
      lfs.enable = true;

      settings = {
        pull.rebase = true;
        am.threeWay = true;
      };
    };

    nix-index-database.comma.enable = true;

    tmux = {
      enable = true;
      clock24 = true;
      extraConfig = ''
        set -ga terminal-overrides ',xterm*:smcup@:rmcup@'
      '';
    };

    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      nix-direnv.enable = true;
    };
  };

  services.ssh-agent = {
    enable = true;
    defaultMaximumIdentityLifetime = 60;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  xdg.configFile =
    (lib.mapAttrs' (name: flake: {
      name = "nix/inputs/${name}";
      value.source = flake.outPath;
    }) inputs)
    // {
      "distrobox/distrobox.conf".text = ''
        container_image_default="docker.io/library/archlinux"
        #non_interactive="1"
      '';
    };

  fonts.fontconfig.enable = false;

  home = {
    stateVersion = "25.11";

    sessionVariables.EDITOR = "micro";

    packages = with pkgs; [
      ssh-to-age
      btop
      p7zip
      pciutils
      killall
      lsof
      powertop
      htop
      wget
      smartmontools
      usbutils
      unrar
      file
      gdu
      e2fsprogs
      nix-tree
      gptfdisk
      iotop
      pstree
      nvd
      manix
      deadnix
      nixos-generators
      nix-melt
      nurl
      statix
      duperemove
      compsize
      git-extras
      nix-output-monitor
      reptyr
      inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}.nix-alien
      b4
      nix-serve-ng
      ps_mem
      procps
      borgbackup
      dix
      mosh
      bubblewrap
      nixos-shell
    ];
  };
}
