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
        verbatimConfig = ''
          cgroup_device_acl = [
            "/dev/null", "/dev/full", "/dev/zero",
            "/dev/random", "/dev/urandom",
            "/dev/ptmx", "/dev/kvm",
            "/dev/kvmfr0"
          ]
        '';

        ovmf = {
          enable = true;
          packages = [ pkgs.OVMFFull.fd ];
        };

        swtpm.enable = true;

        vhostUserPackages = [ pkgs.virtiofsd ];
      };
    };

    spiceUSBRedirection.enable = true;
  };

  services.persistent-evdev = {
    enable = true;
    devices.persist-mouse1 = "usb-Rapoo_Rapoo_Gaming_Device_20231211-event-mouse";
  };
}
