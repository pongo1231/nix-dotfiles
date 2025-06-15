{
  # https://github.com/CachyOS/CachyOS-Settings/blob/master/usr/lib/sysctl.d/99-cachyos-settings.conf
  "vm.swappiness" = 150;
  "vm.vfs_cache_pressure" = 50;
  "vm.dirty_bytes" = 268435456;
  "vm.page-cluster" = 0;
  "vm.dirty_background_bytes" = 67108864;
  "vm.dirty_writeback_centisecs " = 1500;
  "fs.inotify.max_user_instances" = 1024;
  "kernel.nmi_watchdog" = 0;
  "kernel.printk" = "3 3 3 3";
  "kernel.kptr_restrict" = 2;
  "kernel.kexec_load_disabled" = 1;
  "net.core.netdev_max_backlog" = 4096;
  "fs.file-max" = 2097152;

  # https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
  "vm.watermark_boost_factor" = 0;
  "vm.watermark_scale_factor" = 125;

  "vm.max_map_count" = 2147483642; # awareness through https://www.phoronix.com/news/Fedora-39-VM-Max-Map-Count
  "dev.i915.perf_stream_paranoid" = 0;
  "kernel.sysrq" = 1;
  "kernel.core_pattern" = "/dev/null";

  "vm.compact_unevictable_allowed" = 1;
  "vm.compaction_proactiveness" = 20;
}
