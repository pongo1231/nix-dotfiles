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

  system = {
    nixos-init.enable = false;
    etc.overlay.enable = false;
  };

  boot = {
    loader.systemd-boot.enable = lib.mkForce false;

    binfmt.emulatedSystems = [
      "aarch64-linux"
    ];
  };

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

  environment.systemPackages = with pkgs; [
    wget # for vs code server
  ];
}
