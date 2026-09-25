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
    inputs.omp.homeManagerModules.default

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

    stateVersion = "25.11";

    sessionVariables.EDITOR = "micro";

    packages = with pkgs; [
      btop
      p7zip
      pciutils
      killall
      lsof
      powertop
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
      nvd
      manix
      deadnix
      nurl
      statix
      duperemove
      compsize
      git-extras
      reptyr
      inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}.nix-alien
      ps_mem
      procps
      borgbackup
      dix
      bubblewrap
      nixos-shell
      udp-reverse-tunnel
      psmisc
    ];
  };

  programs = {
    fzf = {
      enable = true;
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
    };

    omp = {
      enable = lib.mkDefault true;
      settings = {
        startup = {
          quiet = true;
          checkUpdate = false;
        };
        hideThinkingBlock = true;

        theme.dark = "titanium";
        symbolPreset = "unicode";
        composer.shape = "band";
        modelRoles.default = "deepseek/deepseek-v4-flash-vision-exp";
        setupVersion = 2;
      };
    };
  };

  services.ssh-agent = {
    enable = true;
    defaultMaximumIdentityLifetime = 60;
  };

  xdg.configFile =
    (lib.mapAttrs' (name: flake: {
      name = "nix/inputs/${name}";
      value.source = flake.outPath;
    }) inputs)
    // {
      "distrobox/distrobox.conf".text = ''
        container_image="docker.io/library/archlinux"
        #non_interactive="1"
      '';
    };

  fonts.fontconfig.enable = false;
}
