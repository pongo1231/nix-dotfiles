{
  system = "aarch64-linux";

  host = {
    # install bootloader step fails with rust uutils atm
    overlay.enableUutils = false;
    pongoKernel = {
      enable = false;
      crossCompile = {
        host = "x86_64-linux";
        target = "aarch64-multiplatform";
      };
    };
  };
}
