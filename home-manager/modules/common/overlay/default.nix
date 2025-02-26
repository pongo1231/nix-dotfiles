{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      duperemove = prev.duperemove.overrideAttrs (
        finalAttrs: prevAttrs: {
          src = final.fetchFromGitHub {
            owner = "markfasheh";
            repo = "duperemove";
            rev = "cacc30dcf4cd474329abdba08aa1fa8089b019e6";
            hash = "sha256-lpQLa2bnUm8L17uQCON5X//LeL2CAj7GcAA/YWzqgGY=";
          };

          nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [
            final.libbsd
            final.xxHash
          ];
        }
      );
    })
  ];
}
