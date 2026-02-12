{
  pkgs,
  lib,
  ...
}:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; # fixes --experimental flag not applying on boot
  };
  # show bluetooth headset battery level in kde
  systemd.services.bluetooth.serviceConfig.ExecStart = lib.mkForce [
    ""
    "${pkgs.bluez}/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf --experimental"
  ];
}
