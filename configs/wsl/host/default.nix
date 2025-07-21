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
  };

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

  hardware.graphics.enable = true;

  environment.systemPackages = [
    pkgs.wget # for vs code server
  ];
}
