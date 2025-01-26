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
        package = pkgs.qemu_kvm.overrideAttrs (
          finalAttrs: previousAttrs: {
            # for gvt-g to work
            /*
              cephSupport = true;
              patches =
                previousAttrs.patches or [ ]
                ++ [
                  #(patch /qemu/qemu-device-fix.patch)
                  (patch /qemu/qemu_higher_gui_refresh_rate.patch)
                ];
            */
          }
        );

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

  /*
    system.activationScripts.qemu_hook.text = ''
      mkdir -p /var/lib/libvirt/hooks

      cat << EOF > /var/lib/libvirt/hooks/qemu
      #!/bin/sh

      GUEST_NAME="\$1"
      HOOK_NAME="\$2"
      STATE_NAME="\$3"
      MISC="\''${@:4}"

      if [[ \$GUEST_NAME != *"_igpu"* ]]; then
        exit 0
      fi

      if [ \$HOOK_NAME = "prepare" ] && [ \$STATE_NAME = "begin" ]; then
        echo "286d3cce-2b6e-4e71-8045-8904caaa3ab0" > "/sys/bus/pci/devices/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_4/create"
      elif [ \$HOOK_NAME = "release" ] && [ \$STATE_NAME = "end" ]; then
        echo 1 > "/sys/bus/pci/devices/0000:00:02.0/286d3cce-2b6e-4e71-8045-8904caaa3ab0/remove"
      fi
      EOF

      chmod +x /var/lib/libvirt/hooks/qemu
    '';
  */

  system.activationScripts.ovmf_secure_boot.text = ''
    mkdir -p /var/run/libvirt/nix-ovmf

    ln -sf "${config.virtualisation.libvirtd.qemu.package}/share/qemu/edk2-x86_64-secure-code.fd" /var/run/libvirt/nix-ovmf/
    ln -sf "${config.virtualisation.libvirtd.qemu.package}/share/qemu/edk2-i386-vars.fd" /var/run/libvirt/nix-ovmf/
  '';
}
