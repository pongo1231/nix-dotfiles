{ }:
(final: prev: {
  duperemove = prev.duperemove.overrideAttrs (
    finalAttrs: prevAttrs: {
      src = final.fetchFromGitHub {
        owner = "markfasheh";
        repo = "duperemove";
        rev = "c389d3d5309ed5641aae8cb5d7a255019396bf86";
        hash = "sha256-5yyeHGttSlVro+j72VUBoscwIPd4scsQ8X2He4xWFJU=";
      };

      nativeBuildInputs = prevAttrs.nativeBuildInputs ++ [
        final.libbsd
        final.xxHash
      ];

      postPatch = ''
        substituteInPlace Makefile --replace "--std=c23" "--std=c2x"
        substituteInPlace results-tree.h --replace "// TODO: delete this" "#include \"list.h\""
        substituteInPlace results-tree.h --replace "struct list_head {" "struct list_head_b {"
      '';
    }
  );
})
