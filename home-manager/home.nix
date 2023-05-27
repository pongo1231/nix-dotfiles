{ config
, pkgs
, lib
, options
, specialArgs
, modulesPath
, inputs
}: {
  home.username = "pongo";
  home.homeDirectory = "/home/pongo";
  home.sessionVariables.NIX_PATH = "nixpkgs=${config.xdg.configHome}/nix/inputs/nixpkgs$\{NIX_PATH:+:$NIX_PATH}";

  xdg.configFile."nix/inputs/nixpkgs".source = inputs.nixpkgs;

  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  nixpkgs.config.allowUnfreePredicate = pkg: true;

  home.packages = with pkgs; [
    firefox
    gotop
    vscodium
    kate
    flameshot
    p7zip
    ghidra
    pciutils
    ark
    virt-manager
    nvtop
    intel-gpu-tools
    killall
    authy
    lsof
    ((discord.override { nss = nss_latest; /* workaround to fix links not opening browsers */ }).overrideAttrs (finalAttrs: previousAttrs: rec {
      desktopItem = previousAttrs.desktopItem.override { exec = "Discord --disable-smooth-scrolling"; };
      installPhase = builtins.replaceStrings [ "${previousAttrs.desktopItem}" ] [ "${desktopItem}" ] previousAttrs.installPhase;
    }))
    ocs-url
    nil
    nixpkgs-fmt
    filelight
    compsize
    powertop
    htop
    wget
    smartmontools
    libreoffice
    direnv
    usbutils
    vlc
    unrar
    file
    gdu
    btdu
    nix-diff
    e2fsprogs
    manix
    nix-du
    nix-prefetch
    nix-tree
    nvd
    statix
    nixpkgs-review
    gimp
    audacity
    kdeconnect
  ];

  programs.git = {
    enable = true;
    userName = "pongo1231";
    userEmail = "pongo1999712@gmail.com";
  };

  programs.firefox = {
    profiles = {
      settings = {
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
      };
    };
  };

  # workaround for plasma-browser-integration
  home.file.".mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json".source = "${pkgs.plasma-browser-integration}/lib/mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json";

  # to allow distrobox apps to access x server
  home.file.".xprofile" = {
    text = "${pkgs.xorg.xhost}/bin/xhost +si:localuser:$USER";
    executable = true;
  };

  home.stateVersion = "22.05";
}
