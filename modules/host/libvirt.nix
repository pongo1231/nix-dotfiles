{
  patch,
  pkgs,
  ...
}:
{
  virtualisation = {
    libvirtd = {
      enable = true;
      package = pkgs.libvirt.overrideAttrs (prev: {
        patches = (prev.patches or [ ]) ++ [
          (patch /libvirt/libvirt-11.0.0-venus2.patch)
        ];
      });

      qemu = {
        package =
          (pkgs.qemu_kvm.override {
            buildPackages = pkgs.buildPackages // {
              stdenv = pkgs.gcc15Stdenv;
            };
            stdenv = pkgs.gcc15Stdenv;
          }).overrideAttrs
            (prev: {
              patches = (prev.patches or [ ]) ++ [
                (patch /qemu/qemu-9.2.1-venus.patch)
              ];

              NIX_CFLAGS_COMPILE = "-march=x86-64-v3";
            });

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
