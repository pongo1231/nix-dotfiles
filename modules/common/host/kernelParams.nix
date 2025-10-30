config: [
  "quiet"
  "splash"
  "loglevel=3"
  "rd.udev.log_level=3"
  "kvm.ignore_msrs=1"
  "msr.allow_writes=on"
  "cgroup_no_v1=all"
  "transparent_hugepage=always"
  "transparent_hugepage_shmem=within_size"
  "transparent_hugepage_tmpfs=within_size"
  "preempt=full"
  "threadirqs"
  "nohz_full=all"
  "rcu_nocbs=0-N"
  "rcutree.enable_rcu_lazy=1"
  "log_buf_len=4M"
  "split_lock_detect=off"
  "panic=-1"

  # Hardening
  "randomize_kstack_offset=on"
  "efi=disable_early_pci_dma"
]
