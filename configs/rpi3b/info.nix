{
  system = "aarch64-linux";

  # install bootloader step fails with rust uutils atm
  host.overlay.enableUutils = false;
}
