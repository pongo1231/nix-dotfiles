{ config, lib, ... }:
let
  cfg = config.pongo.kernelParams;
in
{
  options.pongo.kernelParams.remove = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
  };

  config.boot.kernelParams = lib.subtractLists cfg.remove [
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
    #"preempt=full"
    #"threadirqs"
    #"rcu_nocbs=0-N"
    "rcutree.enable_rcu_lazy=1"
    "log_buf_len=4M"
    "split_lock_detect=off"
    "modprobe.blacklist=nouveau"

    # Hardening
    "randomize_kstack_offset=on"
    "efi=disable_early_pci_dma"
  ];
}
