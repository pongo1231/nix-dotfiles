{
  config,
}:
let
  sched =
    if config.pongo.pongoKernel.enable then
      {
        slow = "adios";
        fast = "adios";
      }
    else
      {
        slow = "bfq";
        fast = "kyber";
      };
in
''
  SUBSYSTEM=="pci", ATTR{power/control}="auto"

  ACTION=="add|change", SUBSYSTEM=="block", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="${sched.slow}"
  ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="mmcblk?", ATTR{queue/scheduler}="${sched.slow}"

  ACTION=="add|change", SUBSYSTEM=="block", ATTR{queue/rotational}=="0", KERNEL=="nvme?n?", ATTR{queue/scheduler}="${sched.fast}"
  ACTION=="add|change", SUBSYSTEM=="block", ATTR{queue/rotational}=="0", KERNEL=="sd?", ATTR{queue/scheduler}="${sched.fast}"
''
