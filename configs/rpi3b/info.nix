{
  system = "aarch64-linux";
  host.pongoKernel = {
    enable = true;
    crossCompile = {
      host = "x86_64-linux";
      target = "aarch64-multiplatform";
    };
  };
}
