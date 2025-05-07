{
  inputs,
  patch,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    inputs.chaotic.nixosModules.default
  ];

  hardware.graphics =
    let
      patchMesa =
        mesa:
        mesa.overrideAttrs (
          prevAttrs: {
            patches = prevAttrs.patches ++ [
              (patch /mesa/24.3.0/gamescope-limiter.patch)
            ];
          }
        );
    in
    {
      # chaotic-nyx's mesa-git module uses mkForce for some reason...
      package = lib.mkOverride 49 (patchMesa pkgs.mesa_git.drivers);
      package32 = lib.mkOverride 49 (patchMesa pkgs.mesa32_git.drivers);
    };

  chaotic.mesa-git.enable = true;
}
