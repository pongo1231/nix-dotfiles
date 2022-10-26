{
  config,
  pkgs,
  nixpkgs,
  ...
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
    alejandra
    vscodium
    kate
    flameshot
    p7zip
    ghidra
    pciutils
    ark
    virt-manager
    comma
    nix-index
    nvtop
    intel-gpu-tools
    papirus-icon-theme
    killall
    xorg.xhost
    kdeconnect
    authy
    lsof
  ];

  programs.git = {
    enable = true;
    userName = "pongo1231";
    userEmail = "pongo1999712@gmail.com";
  };

  # workaround for plasma-browser-integration
  home.file.".mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json".source = "${pkgs.plasma-browser-integration}/lib/mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json";

  home.stateVersion = "22.05";
}
