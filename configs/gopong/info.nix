{
  host = {
    pongoKernel.enable = true;

    ksm = {
      forceAllProcesses = true;
      patchSystemd = true;
    };
  };
}
