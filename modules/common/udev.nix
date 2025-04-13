{
  cfg,
  config,
  lib,
  ...
}:
let
  cfg = config.pongo;
in
{
  services.udev.extraRules =
    ''
      # auto enable runtime pm for all pci devices
      SUBSYSTEM=="pci", ATTR{power/control}="auto"
    ''
    + lib.optionalString (!cfg.pongoKernel.enable) ''
      # set scheduler for NVMe
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
      # set scheduler for SSD and eMMC
      ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
      # set scheduler for rotating disks
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    '';
}
