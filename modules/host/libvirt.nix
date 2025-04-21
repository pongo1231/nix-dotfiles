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

  environment.systemPackages = with pkgs; [
    libguestfs-with-appliance
  ];

  system.activationScripts.ovmf_secure_boot.text = ''
    mkdir -p /var/run/libvirt/nix-ovmf

    ln -sf "${config.virtualisation.libvirtd.qemu.package}/share/qemu/edk2-x86_64-secure-code.fd" /var/run/libvirt/nix-ovmf/
    ln -sf "${config.virtualisation.libvirtd.qemu.package}/share/qemu/edk2-i386-vars.fd" /var/run/libvirt/nix-ovmf/
  '';
}
