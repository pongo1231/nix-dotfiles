{ inputs
, lib
, pkgs
, ...
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

  system.build.installBootLoader = lib.mkForce "${pkgs.coreutils}/bin/true";

  wsl = {
    enable = true;
    defaultUser = "pongo";
    usbip.enable = true;
    useWindowsDriver = true;
    nativeSystemd = true;
    startMenuLaunchers = true;
  };

  hardware.graphics = {
    extraPackages = with pkgs; [
      mesa.drivers
      libvdpau-va-gl
      (libedit.overrideAttrs (attrs: { postInstall = (attrs.postInstall or "") + ''ln -s $out/lib/libedit.so $out/lib/libedit.so.2''; }))
    ];
  };

  systemd.oomd.enable = lib.mkForce false;

  networking.networkmanager.enable = lib.mkForce false;
}
