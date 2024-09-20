{ config
, pkgs
, inputs
, ...
}: {
  imports = [
    ./helpers.nix
    ./suspender.nix
  ];

  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  nixpkgs.config.allowUnfreePredicate = pkg: true;

  programs.git = {
    enable = true;
    userName = "pongo1231";
    userEmail = "pongo1999712@gmail.com";
  };

  xdg.configFile = {
    "nix/inputs/nixpkgs".source = inputs.nixpkgs;

    "distrobox/distrobox.conf".text = ''
      container_image_default="docker.io/library/archlinux"
      non_interactive="1"
    '';
  };

  home = {
    stateVersion = "22.05";

    sessionVariables.NIX_PATH = "nixpkgs=${config.xdg.configHome}/nix/inputs/nixpkgs:$\{NIX_PATH:+:$NIX_PATH}";

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
      #nix-du
      nix-tree
      tmux
      borgbackup
      gptfdisk
      iotop
    ];
  };
}
