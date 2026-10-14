{
  inputs,
  config,
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

    activationScripts.shimSystemd.text = lib.mkForce ''
      echo "setting up /sbin/init shim..."
      rm -f /sbin/init
      ln -s ${config.system.build.nativeUtils}/bin/systemd-shim /sbin/init
    '';
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

  services.scx-loader.enable = false;

  environment.systemPackages = with pkgs; [
    wget # for vs code server
  ];
}
