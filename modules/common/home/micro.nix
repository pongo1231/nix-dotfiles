{ pkgs, ... }:
{
  programs.micro = {
    enable = true;
    package = pkgs.micro-with-xclip;

    settings = {
      tabstospaces = true;
      ftoptions = false;
      tabmovement = true;
    };
  };

  xdg.configFile."micro/plug/detectindent".source = pkgs.fetchFromGitHub {
    owner = "dmaluka";
    repo = "micro-detectindent";
    rev = "2c725615920a1686c1c46a321c1973a65eea480b";
    sha256 = "sha256-XSNsfrw1xdfwnJfFI3n2DC7a6MK0X0GyB27m5+8HMl8=";
  };
}
