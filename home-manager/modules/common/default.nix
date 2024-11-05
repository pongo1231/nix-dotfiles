{ inputs
, config
, pkgs
, lib
, ...
}: {
  imports = [
    ./helpers.nix
    ./suspender.nix
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
    };

    nix-index-database.comma.enable = true;
  };

  xdg.configFile = (lib.mapAttrs' (name: flake: { name = "nix/inputs/${name}"; value.source = flake.outPath; }) inputs)
    // {
    "distrobox/distrobox.conf".text = ''
      container_image_default="docker.io/library/archlinux"
      non_interactive="1"
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
      pstree
      nvd
      manix
      nil
      nixpkgs-fmt
      deadnix
      direnv
      nixos-generators
      nix-melt
      nurl
      nix-health
      duperemove
      compsize
      inputs.nix-alien.packages.${system}.nix-alien
      inputs.nix-be.packages.${system}.nix-be
    ];
  };
}
