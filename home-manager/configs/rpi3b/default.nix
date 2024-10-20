{ pkgs
, ...
}:
{
  home.packages = with pkgs; [
    box64
    box86
  ];
}
