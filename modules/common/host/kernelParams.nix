config: [
  "quiet"
  "splash"
  "loglevel=3"
  "rd.udev.log_level=3"
  "kvm.ignore_msrs=1"
  "ec_sys.write_support=1"
  "msr.allow_writes=on"
  "cgroup_no_v1=all"
  "mitigations=off"
  "transparent_hugepage=${if config.pongo.pongoKernel.enable then "defer" else "always"}"
  "transparent_hugepage_shmem=within_size"
  "transparent_hugepage_tmpfs=within_size"
]
