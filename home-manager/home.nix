{ config
, pkgs
, lib
, options
, specialArgs
, modulesPath
, inputs
}: {
  imports = [
    ./suspender.nix
  ];

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
    authy
    lsof
    ((discord.override { nss = nss_latest; /* workaround to fix links not opening browsers */ }).overrideAttrs (finalAttrs: previousAttrs: rec {

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
    ungoogled-chromium
    wget
    smartmontools
    libreoffice
    direnv
    usbutils
    vlc
    unrar
    file
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
    text = "xhost +si:localuser:$USER";
    executable = true;
  };

  home.stateVersion = "22.05";
}
