{ config, lib, ... }:
let
  cfg = config.pongo.boot;
in
{
  options.pongo.boot.useFullPreempt = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };

  config.boot.kernelParams = if cfg.useFullPreempt then [ "preempt=full" ] else [ "preempt=lazy" ];
}
