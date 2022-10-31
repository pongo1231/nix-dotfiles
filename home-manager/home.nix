{ config
, pkgs
, nixpkgs
, lib
, options
, specialArgs
, modulesPath
}: {
  nixpkgs.overlays = [
    (self: super: {
      vgmstream = super.vgmstream.overrideAttrs (finalAttrs: previousAttrs: {
        cmakeFlags = [
          "-DUSE_CELT=OFF"
        ];
      });
    })
  ];

  home.username = "pongo";
  home.homeDirectory = "/home/pongo";

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
    papirus-icon-theme
    killall
    xorg.xhost
    kdeconnect
    authy
    lsof
    (discord.overrideAttrs (finalAttrs: previousAttrs: rec {
      desktopItem = previousAttrs.desktopItem.override { exec = "Discord --disable-smooth-scrolling"; };
      installPhase = builtins.replaceStrings [ "${previousAttrs.desktopItem}" ] [ "${desktopItem}" ] previousAttrs.installPhase;
    }))
    ocs-url
    gparted
    nil
    nixpkgs-fmt
    filelight
    compsize
    powertop
    htop
  ];

  programs.git = {
    enable = true;
    userName = "pongo1231";
    userEmail = "pongo1999712@gmail.com";
  };

  # workaround for plasma-browser-integration
  home.file.".mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json".source = "${pkgs.plasma-browser-integration}/lib/mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json";

  # to allow distrobox apps to access x server
  home.file.".xprofile" = {
    text = "xhost +si:localuser:$USER";
    executable = true;
  };

  home.stateVersion = "22.05";
}
