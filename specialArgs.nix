{
  prefix,
  isNixosModule,
  lib,
  ...
}@args:
let
  modulesInPath =
    path: file:
    let
      fileStr = builtins.toString file;
      splitFile = lib.splitString "/" fileStr;
      splitLen = builtins.length splitFile;
      lastIdx = splitLen - 1;
      splitLastIsNixFile = lib.hasSuffix ".nix" (builtins.elemAt splitFile lastIdx);
      indices = if splitLen < 2 then [ ] else builtins.genList (i: i + 1) (splitLen - 1);
      filePathsStr = lib.unique (
        builtins.foldl' (
          acc: x:
          let
            split = builtins.elemAt splitFile x;
            allowDefault = x != lastIdx || !splitLastIsNixFile;
          in
          acc
          ++ lib.concatMap (
            x':
            if lib.hasSuffix ".nix" x' then
              [ x' ]
            else
              let
                paths = [
                  "${x'}/${split}"
                  "${x'}/${split}/${prefix}"
                  "${x'}/${prefix}/${split}"
                ];
              in
              lib.concatMap (
                p:
                let
                  d = "${p}/default.nix";
                in
                lib.optionals (builtins.pathExists ./${p}) [ p ]
                ++ lib.optionals (allowDefault && builtins.pathExists ./${d}) [ d ]
              ) paths
          ) acc
        ) [ path ] indices
      );
      filePaths = builtins.map (x: ./${x}) (builtins.filter (x: lib.hasSuffix ".nix" x) filePathsStr);
      filePathsLen = builtins.length filePaths;
    in
    if filePathsLen == 0 then builtins.throw "Could not find module ${fileStr}" else filePaths;

  genModulesAttrset = path: multipleName: oneName: {
    ${multipleName} = modulesInPath path;

    ${oneName} =
      file:
      let
        foundModules = modulesInPath path file;
        foundModulesLen = builtins.length foundModules;
      in
      if foundModulesLen == 1 then
        builtins.elemAt foundModules 0
      else
        abort (
          if foundModulesLen == 0 then
            "${oneName} \"${file}\" not found"
          else
            "Ambiguous ${oneName} \"${file}\": ${builtins.foldl' (acc: x: "${acc} \"${x}\"") "" foundModules}"
        );
  };
in
genModulesAttrset "modules" "modules" "module"
// genModulesAttrset "roles" "roles" "role"
// {
  configInfo = {
    type = prefix;
    inherit isNixosModule;
  };

  patch = file: ./patches/${file};
  pkg = file: ./pkgs/${file};

  withSecrets =
    user:
    {
      store ? "default.yaml",
      owner ? null,
      group ? null,
    }:
    secrets: {
      sops.secrets = lib.mapAttrs' (name: value: {
        inherit name;
        value = {
          sopsFile = ./secrets/${user}/${value.store or store};
          format =
            if lib.hasSuffix ".yaml" store then
              "yaml"
            else if lib.hasSuffix ".json" store then
              "json"
            else if lib.hasSuffix ".ini" store then
              "ini"
            else if lib.hasSuffix ".env" store then
              "dotenv"
            else
              "binary";
        }
        // lib.optionalAttrs (owner != null) { inherit owner; }
        // lib.optionalAttrs (group != null) {
          inherit group;
          mode = "0440";
        }
        // builtins.removeAttrs value [ "store" ];
      }) secrets;
    };
}
// builtins.removeAttrs args [
  "prefix"
  "isNixosModule"
  "lib"
]
