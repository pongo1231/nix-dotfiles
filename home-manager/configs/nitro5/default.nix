{
  module,
  ...
}:
{
  imports = [
    (import (module /gpu) [
      "intel"
      "nvidia"
    ])
  ];
}
