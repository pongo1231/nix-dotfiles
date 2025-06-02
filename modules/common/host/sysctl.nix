{
  # https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
  "vm.swappiness" = 200;
  "vm.page-cluster" = 0;
  "vm.watermark_boost_factor" = 0;
  "vm.watermark_scale_factor" = 125;

  "vm.max_map_count" = 2147483642; # awareness through https://www.phoronix.com/news/Fedora-39-VM-Max-Map-Count
  "dev.i915.perf_stream_paranoid" = 0;
  "kernel.sysrq" = 1;
  "kernel.core_pattern" = "/dev/null";

  # https://github.com/pop-os/default-settings/blob/master_noble/etc/sysctl.d/10-pop-default-settings.conf
  "vm.dirty_bytes" = 268435456;
  "vm.dirty_background_bytes" = 134217728;
  "fs.inotify.max_user_instances" = 1024;

  "vm.compact_unevictable_allowed" = 1;
  "vm.compaction_proactiveness" = 20;

  "kernel.split_lock_mitigate" = 0;

  # Cachyos
  "vm.vfs_cache_pressure" = 50;
  "vm.dirty_writeback_centisecs" = 1500;
  "net.core.netdev_max_backlog" = 4096;
  "fs.file-max" = 2097152;
}
