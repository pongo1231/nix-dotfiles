{ inputs
, lib
, pkgs
, ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
  ];

  wsl = {
    enable = true;
    defaultUser = "pongo";
    usbip.enable = true;
    useWindowsDriver = true;
  };

  systemd.oomd.enable = lib.mkForce false;

  boot.loader.systemd-boot.enable = lib.mkForce false;

  system.build.installBootLoader = lib.mkForce "${pkgs.coreutils}/bin/true";
}
