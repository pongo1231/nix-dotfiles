{
  args,
}:
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

    (module /common/nix.nix)
    (module /common/overlay.nix)
    (module /common/sops.nix)

    ./fish.nix
    ./helpers.nix
    ./suspender.nix
  ];

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

      userName = "pongo1231";
      userEmail = "pongo@gopong.dev";

      extraConfig = {
        pull.rebase = true;
        am.threeWay = true;
        core.fileMode = false;
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
    stateVersion = "22.05";

    packages = with pkgs; [
      sops
      ssh-to-age
      direnv
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
      nix-du
      graphviz
      nix-tree
      borgbackup
      gptfdisk
      iotop
      micro
      xclip # for micro
      pstree
      nvd
      manix
      nixd
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
      inputs.nix-alien.packages.${system}.nix-alien
      jj
      #lazyjj
      b4
      nix-serve-ng
      ps_mem
      procps
      smem
    ];
  };
}
