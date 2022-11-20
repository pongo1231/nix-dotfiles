{ config
, fetchpatch
, pkgs
, lib
, ...
}:
let
  qemu_file = ''
    #!${pkgs.stdenv.shell}

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
    #!${pkgs.stdenv.shell}

    echo "286d3cce-2b6e-4e71-8045-8904caaa3ab0" > "/sys/bus/pci/devices/0000:00:02.0/mdev_supported_types/i915-GVTg_V5_4/create"
  '';
  end_file = ''
    #!${pkgs.stdenv.shell}
    
    echo 1 > "/sys/bus/pci/devices/0000:00:02.0/286d3cce-2b6e-4e71-8045-8904caaa3ab0/remove"
  '';

  hooks = [
    "win10_igpu"
    "win10_igpu_dgpu"
  ];
in
{
  nixpkgs.overlays = [
    (self: super: {
      qemu_patched = pkgs.unstable.qemu_kvm.overrideAttrs (finalAttrs: previousAttrs: {
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
    })
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_patched;
      ovmf.enable = true;
    };
  };

  systemd.services.libvirtd-config.script = lib.mkAfter (''
    mkdir -p /var/lib/libvirt/hooks
    rm -rf /var/lib/libvirt/hooks/*
    
    echo '${qemu_file}' > /var/lib/libvirt/hooks/qemu
    chmod +x /var/lib/libvirt/hooks/qemu
  '' + lib.strings.concatMapStrings
    (hook:
      ''

        mkdir -p /var/lib/libvirt/hooks/qemu.d/${hook}/prepare/begin
        echo '${begin_file}' > /var/lib/libvirt/hooks/qemu.d/${hook}/prepare/begin/begin.sh
        chmod +x /var/lib/libvirt/hooks/qemu.d/${hook}/prepare/begin/begin.sh

        mkdir -p /var/lib/libvirt/hooks/qemu.d/${hook}/release/end
        echo '${end_file}' > /var/lib/libvirt/hooks/qemu.d/${hook}/release/end/end.sh
        chmod +x /var/lib/libvirt/hooks/qemu.d/${hook}/release/end/end.sh
      ''
    )
    hooks);
}
