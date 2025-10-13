config:
{
  "kernel.nmi_watchdog" = 0;
  "kernel.printk" = "3 3 3 3";
  "kernel.kptr_restrict" = 2;
  "kernel.sysrq" = 1;
}
// (
  if config.pongo.pongoKernel.enable then
    { }
  else
    {
      "vm.page-cluster" = 0;
      "vm.watermark_boost_factor" = 0;
      "vm.compact_unevictable_allowed" = 0;
      "vm.compaction_proactiveness" = 0;
      "vm.swappiness" = 100;
      "vm.dirty_writeback_centisecs" = 1000;
      "vm.dirty_background_ratio" = 5;
      "kernel.sched_cfs_bandwidth_slice_us" = 3000;
    }
)
