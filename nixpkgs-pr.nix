{ pr }:
let
  pkgs = import <nixpkgs> {};
  patches = [
    (builtins.fetchurl {
      url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/${pr}.patch";
    })
  ];
in pkgs.runCommand "nixpkgs-PR${pr}" { inherit patches; } ''
  cp -R ${pkgs.path} $out
  chmod -R +w $out
  for p in $patches; do
    echo "Applying patch $p"
    patch -d $out -p1 < "$p"
  done
''
