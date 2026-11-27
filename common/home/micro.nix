{ pkgs, ... }:
{
  programs.micro = {
    enable = true;
    package = pkgs.micro-with-xclip;

    settings = {
      ftoptions = false;
      tabmovement = true;
      tabsize = 2;
    };
  };

  xdg.configFile."micro/plug/detectindent".source = pkgs.fetchFromGitHub {
    owner = "dmaluka";
    repo = "micro-detectindent";
    rev = "0ffe2b84976dcc14525fb784a26eb05f72b1665b";
    sha256 = "sha256-APu4FfrnWCUhs+aBnOFuxt9UK2b7XPeqH2Xbt5SLWkE=";
  };
}
