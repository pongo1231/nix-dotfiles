{
  inputs,
  lib,
  ...
}:
{
  imports = [
  	inputs.avf.nixosModules.avf
  ];

  networking.useDHCP = lib.mkForce false;

  services.zram-generator.settings.zram0.zram-size = lib.mkForce "200 / 100 * zram";
}
