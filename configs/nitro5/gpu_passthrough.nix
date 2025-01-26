{
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    (pkgs.writeScriptBin ''vfio-bind-gpu'' ''
      #!${pkgs.stdenv.shell}

      [ "$UID" -eq 0 ] || exec sudo "$0" "$@"

      trap "" HUP

      systemctl stop display-manager
      systemctl stop nvidia-persistenced

      ${pkgs.killall}/bin/killall .kwin_wayland-wrapped

      ${pkgs.kmod}/bin/rmmod nvidia_uvm
      ${pkgs.kmod}/bin/rmmod nvidia_drm
      ${pkgs.kmod}/bin/rmmod nvidia_modeset
      #${pkgs.kmod}/bin/rmmod nvidia

      ${pkgs.libvirt}/bin/virsh nodedev-detach pci_0000_01_00_0
      ${pkgs.libvirt}/bin/virsh nodedev-detach pci_0000_01_00_1

      systemctl start display-manager
    '')

    (pkgs.writeScriptBin ''vfio-unbind-gpu'' ''
      #!${pkgs.stdenv.shell}

      [ "$UID" -eq 0 ] || exec sudo "$0" "$@"

      trap "" HUP

      systemctl stop display-manager

      ${pkgs.killall}/bin/killall .kwin_wayland-wrapped

      ${pkgs.libvirt}/bin/virsh nodedev-reattach pci_0000_01_00_0
      ${pkgs.libvirt}/bin/virsh nodedev-reattach pci_0000_01_00_1

      ${pkgs.kmod}/bin/modprobe nvidia
      ${pkgs.kmod}/bin/modprobe nvidia_drm
      ${pkgs.kmod}/bin/modprobe nvidia_modeset
      ${pkgs.kmod}/bin/modprobe nvidia_uvm

      systemctl start display-manager
      systemctl start nvidia-persistenced
    '')
  ];
}
