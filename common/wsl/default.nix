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

  boot.loader.systemd-boot.enable = lib.mkForce false;

  system.build.installBootLoader = lib.mkForce "${pkgs.coreutils}/bin/true";
}
