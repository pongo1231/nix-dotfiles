{
  config,
  pkgs,
  ...
}:
{
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package =
          (pkgs.qemu_kvm.override {
            buildPackages = pkgs.buildPackages // {
              stdenv = pkgs.gcc15Stdenv;
            };
            stdenv = pkgs.gcc15Stdenv;
          }).overrideAttrs
            {
              NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
            };

        verbatimConfig = ''
          cgroup_device_acl = [
            "/dev/null", "/dev/full", "/dev/zero",
            "/dev/random", "/dev/urandom",
            "/dev/ptmx", "/dev/kvm",
            "/dev/kvmfr0"
          ]
        '';

        swtpm.enable = true;

        vhostUserPackages = [ pkgs.virtiofsd ];
      };
    };

    spiceUSBRedirection.enable = true;
  };
}
