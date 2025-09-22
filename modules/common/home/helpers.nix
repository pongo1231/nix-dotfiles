{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # https://gist.github.com/hellwolf/39feed6c494b4b93ebbd6e52aba2e8df
    (pkgs.writeScriptBin "trace-symlink" ''
      #!${pkgs.stdenv.shell}
      readlinkWithPrint() {
          link=$(readlink "$1")
          p=$link
          [ -n "''${p##/*}" ] && p=$(dirname "$1")/$link
          echo "$p"
          [ -h "$p" ] && readlinkWithPrint "$p"
      }
      a=$1
      [ -e "$a" ] && {
          echo "$a"
          # extra print if one of the parent is also a symlink
          b=$(basename "$a")
          d=$(dirname "$a")
          p=$(readlink -f "$d")/$b
          [ "$a" != "$p" ] && echo "$p"

          # follows the symlink
          if [ -L "$p" ];then
              readlinkWithPrint "$p"
          fi
      }
    '')
    (pkgs.writeScriptBin "trace-which" ''
      #!${pkgs.stdenv.shell}
      a=$(which "$1") && exec trace-symlink "$a"
    '')

    # https://wiki.tnonline.net/w/Blog/Zswap_statistics
    bc
    (pkgs.writeScriptBin "zswapstatus" ''
      #!${pkgs.stdenv.shell}
      sudo ${./zswapstatus.sh}
    '')
  ];
}
