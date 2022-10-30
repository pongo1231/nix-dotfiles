{ config
, fetchpatch
, pkgs
, lib
, ...
}:
let
  qemu_file = ''
    #!/usr/bin/env bash

    GUEST_NAME="$1"
    HOOK_NAME="$2"
    STATE_NAME="$3"
    MISC="$\{@:4}"

    BASEDIR="$(dirname $0)"

    HOOKPATH="$BASEDIR/qemu.d/$GUEST_NAME/$HOOK_NAME/$STATE_NAME"

    set -e

    if [ -f "$HOOKPATH" ] && [ -s "$HOOKPATH"] && [ -x "$HOOKPATH" ]; then
        eval \"$HOOKPATH\" "$@"
    elif [ -d "$HOOKPATH" ]; then
        while read file; do
            # check for null string
            if [ ! -z "$file" ]; then
              eval \"$file\" "$@"
            fi
        done <<< "$(find -L "$HOOKPATH" -maxdepth 1 -type f -executable -print;)"
    fi
  '';
  begin_file = ''
    #!/usr/bin/env sh
    echo "286d3cce-2b6e-4e71-8045-8904caaa3ab0" > "/sys/bus/pci/devices/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_4/create"
  '';
  end_file = ''
    #!/usr/bin/env sh
    echo 1 > "/sys/bus/pci/devices/0000:00:02.0/286d3cce-2b6e-4e71-8045-8904caaa3ab0/remove"
  '';
in
{
  nixpkgs.overlays = [
    (self: super: {
      qemu_patched = super.qemu_kvm.overrideAttrs (finalAttrs: previousAttrs: {
        # for gvt-g to work
        cephSupport = true;
        patches =
          previousAttrs.patches
            or [ ]
          ++ [
            (super.fetchpatch {
              url = "https://gopong.dev/patches/qemu-device-fix.patch";
              sha256 = "pauLaBoyZ7VFV9QEfIzEWgs1ne1o6qHat8JbWcjUWEk=";
            })
            (super.fetchpatch {
              url = "https://gopong.dev/patches/qemu_higher_gui_refresh_rate.patch";
              sha256 = "44/EXk4g1udxAwtlL/OMvHI08ndFoh6QIX3ZjhFHia8=";
            })
          ];
      });
    })
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_patched;
      ovmf.enable = true;
    };
  };

  systemd.services.libvirtd-config.script = lib.mkAfter ''
    mkdir -p /run/libvirt/hooks
    echo '${qemu_file}' > /run/libvirt/hooks/qemu

    mkdir -p /run/libvirt/hooks/qemu.d/win10_igpu_dgpu/prepare
    echo '${begin_file}' > /run/libvirt/hooks/qemu.d/win10_igpu_dgpu/prepare/begin

    mkdir -p /run/libvirt/hooks/qemu.d/win10_igpu_dgpu/release
    echo '${end_file}' > /run/libvirt/hooks/qemu.d/win10_igpu_dgpu/release/end
  '';
}
