{
  module,
  ...
}:
{
  imports = [
    (import (module /gpu) [
      "amd"
      "nvidia"
    ])
  ];
}
