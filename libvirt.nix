{ pkgs
, inputs
, ...
}:
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      # Newer qemu has a regression causing the cursor to not show up under Windows with gvt-g
      package = ((pkgs.callPackage "${inputs.nixpkgs-stable}/pkgs/applications/virtualization/qemu" {
        inherit (pkgs.darwin.apple_sdk.frameworks) CoreServices Cocoa Hypervisor vmnet;
        inherit (pkgs.darwin.stubs) rez setfile;
        inherit (pkgs.darwin) sigtool;
      }).override { hostCpuOnly = true; }).overrideAttrs
        (finalAttrs: previousAttrs: {
          # for gvt-g to work
          cephSupport = true;
          patches =
            previousAttrs.patches
              or [ ]
            ++ [
              ./patches/qemu/qemu-device-fix.patch
              ./patches/qemu/qemu_higher_gui_refresh_rate.patch
            ];
        });
      ovmf.enable = true;
    };
  };

  system.activationScripts.qemu_hook.text = ''
    mkdir -p /var/lib/libvirt/hooks

    cat << EOF > /var/lib/libvirt/hooks/qemu
    #!/bin/sh

    GUEST_NAME="\$1"
    HOOK_NAME="\$2"
    STATE_NAME="\$3"
    MISC="\''${@:4}"

    if [ \$HOOK_NAME = "prepare" ] && [ \$STATE_NAME = "begin" ]; then
      echo "286d3cce-2b6e-4e71-8045-8904caaa3ab0" > "/sys/bus/pci/devices/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_4/create"
    elif [ \$HOOK_NAME = "release" ] && [ \$STATE_NAME = "end" ]; then
      echo 1 > "/sys/bus/pci/devices/0000:00:02.0/286d3cce-2b6e-4e71-8045-8904caaa3ab0/remove"
    fi
    EOF

    chmod +x /var/lib/libvirt/hooks/qemu
  '';
}
