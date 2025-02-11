{
  module,
  patch,
  pkgs,
  ...
}:
{
  imports = [
    (import (module /gpu) [
      "amd"
      "nvidia"
    ])
  ];

  home.packages = with pkgs; [
    (strawberry.overrideAttrs (
      finalAttrs: prevAttrs: {
        patches = (prevAttrs.patches or [ ]) ++ [
          (patch /strawberry/1467.patch)
        ];
        buildInputs = with pkgs; prevAttrs.buildInputs ++ [ projectm ];
        postPatch = ''
          substituteInPlace src/visualizations/projectmvisualization.cpp --replace-fail "QStringList data_paths = QStringList() << QStringLiteral(\"/usr/share\")" "QStringList data_paths = QStringList() << QStringLiteral(\"${pkgs.projectm}/share\")"
        '';
      }
    ))
  ];
}
