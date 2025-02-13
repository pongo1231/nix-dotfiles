{ }:
{
  inputs,
  module,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    (module /common/helpers.nix)
    (module /common/suspender.nix)
  ];

  nix.nixPath = [
    "${config.xdg.configHome}/nix/inputs"
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: true;

  programs = {
    fish = {
      enable = true;

      shellAliases = {
        "cd.." = "cd ..";
        cpufreq = "watch -n.1 'grep \"^[c]pu MHz\" /proc/cpuinfo'";

        ksminfo = "grep -r . /sys/kernel/mm/ksm";
        ksmprofit = "echo | awk -v profit=$(cat /sys/kernel/mm/ksm/general_profit) '{print \"\\033[35m\"profit / 1024 / 1024\" MB\\033[0m\"}'";
      };

      shellInit = ''
        function fish_command_not_found
          , $argv
          return $status
        end
        fish_add_path -maP ~/.local/bin
      '';
    };

    git = {
      enable = true;

      userName = "pongo1231";
      userEmail = "pongo1999712@gmail.com";

      extraConfig = {
        pull.rebase = true;
        am.threeWay = true;
      };
    };

    nix-index-database.comma.enable = true;
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

  home = {
    stateVersion = "22.05";

    packages = with pkgs; [
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
      tmux
      borgbackup
      gptfdisk
      iotop
      micro
      xclip # for micro
      pstree
      nvd
      manix
      nixd
      nixfmt-rfc-style
      deadnix
      direnv
      nixos-generators
      nix-melt
      nurl
      nix-health
      statix
      duperemove
      compsize
      git-extras
      nix-output-monitor
      reptyr
      inputs.nix-alien.packages.${system}.nix-alien
      inputs.nix-be.packages.${system}.nix-be
      jj
      inputs.nixpkgs-stable.legacyPackages.${system}.lazyjj
      inputs.isd.packages.${system}.default
    ];
  };
}
