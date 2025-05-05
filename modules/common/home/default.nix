{
  user,
  args,
}:
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
    inputs.nix-index-database.hmModules.nix-index

    (module /common/nix.nix)
    (module /common/overlay)
    ./sops.nix

    ./helpers.nix
    ./suspender.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
  };

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
        set async_prompt_functions fish_prompt

        function fish_command_not_found
          , $argv
          return $status
        end
        fish_add_path -maP ~/.local/bin
      '';

      plugins = with pkgs.fishPlugins; [
        {
          name = "fzf-fish";
          src = fzf-fish.src;
        }
        {
          name = "autopair";
          src = autopair.src;
        }
        {
          name = "colored-man-pages";
          src = colored-man-pages.src;
        }
        {
          name = "transient-fish";
          src = transient-fish.src;
        }
        {
          name = "sponge";
          src = sponge.src;
        }
        {
          name = "z";
          src = z.src;
        }
        {
          name = "forgit";
          src = forgit.src;
        }
        {
          name = "async-prompt";
          src = async-prompt.src;
        }
      ];
    };

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
      deadnix
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
      lazyjj
      inputs.isd.packages.${system}.default
      b4
    ];
  };
}
