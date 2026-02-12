{ inputs, ... }:
{
  imports = [ "${inputs.nixpkgs}/nixos/modules/profiles/qemu-guest.nix" ];

  services.qemuGuest.enable = true;
}
