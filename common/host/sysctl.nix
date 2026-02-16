config: {
  "vm.page-cluster" = 0;
  "vm.watermark_boost_factor" = 0;

  # hardening
  "kernel.kptr_restrict" = 2;
  "kernel.dmesg_restrict" = 1;
  "kernel.panic" = 60;
  "fs.protected_fifos" = 2;
  "fs.protected_regular" = 2;
  "vm.mmap_rnd_compat_bits" = 16;
  "net.core.bpf_jit_harden" = 2;
  "net.ipv4.ip_local_port_range" = "1024 65535";
  "net.ipv4.tcp_rfc1337" = 1;
}
