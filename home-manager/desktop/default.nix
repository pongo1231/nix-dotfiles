{ pkgs
, ...
}: {
  home.packages = with pkgs; [
    vscodium
    ghidra
    virt-manager
    nvtop
    intel-gpu-tools
    authy
    ((discord.override { nss = nss_latest; /* workaround to fix links not opening browsers */ }).overrideAttrs (prevAttrs: rec {
      desktopItem = prevAttrs.desktopItem.override { exec = "Discord --disable-smooth-scrolling"; };
      installPhase = builtins.replaceStrings [ "${prevAttrs.desktopItem}" ] [ "${desktopItem}" ] prevAttrs.installPhase;
    }))
    libreoffice
    direnv
    gimp
    audacity
    steam
    mangohud
    gamescope
  ];
}