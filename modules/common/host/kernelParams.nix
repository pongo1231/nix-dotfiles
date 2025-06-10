config: [
  "preempt=full"
  "kvm.ignore_msrs=1"
  "ec_sys.write_support=1"
  "msr.allow_writes=on"
  "cgroup_no_v1=all"
  "mitigations=off"
  "split_lock_detect=off"
  "transparent_hugepage=${if config.pongo.pongoKernel.enable then "defer" else "always"}"
  "transparent_hugepage_shmem=always"
  "transparent_hugepage_tmpfs=always"
]
