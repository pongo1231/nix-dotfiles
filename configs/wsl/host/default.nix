{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
  ];

  boot = {
    loader.systemd-boot.enable = lib.mkForce false;

    binfmt.emulatedSystems = [
      "aarch64-linux"
    ];

    tmp.useTmpfs = lib.mkForce false;
  };

  system.build.installBootLoader = lib.mkForce "${pkgs.coreutils}/bin/true";

  networking.useNetworkd = lib.mkForce false;

  systemd.oomd.enable = lib.mkForce false;

  wsl = {
    enable = true;
    defaultUser = "pongo";
    usbip.enable = true;
    useWindowsDriver = true;
    startMenuLaunchers = true;
    interop.register = true;
  };

  hardware.graphics.extraPackages = with pkgs; [
    mesa
    libvdpau-va-gl
    (libedit.overrideAttrs {
      postInstall = ''ln -s $out/lib/libedit.so $out/lib/libedit.so.2'';
    })
  ];

  environment.systemPackages = [
    pkgs.wget # for vs code server
  ];
}
