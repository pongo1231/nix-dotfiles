{
  system = "aarch64-linux";
  roles = [ "server" ];

  host = {
    # install bootloader step fails with rust uutils atm
    overlay.enableUutils = false;

    pongoKernel.crossCompile = {
      host = "x86_64-linux";
      target = "aarch64-multiplatform";
    };

    kernelParams.remove = [ "threadirqs" ];

    ksm.enable = false;
  };
}
