{
  prefix,
  isNixosModule,
  lib,
  ...
}@args:
rec {
  configInfo = {
    type = prefix;
    inherit isNixosModule;
  };

  modules =
    file:
    let
      fileStr = builtins.toString file;
      splitFile = lib.splitString "/" fileStr;
      splitLen = builtins.length splitFile;
      splitLastIsNixFile = lib.hasSuffix ".nix" (builtins.elemAt splitFile (splitLen - 1));
      range = x: if x < 1 then [ ] else range (x - 1) ++ [ x ];
      filePaths = lib.unique (
        builtins.foldl' (acc: x: acc ++ (if lib.hasSuffix ".nix" x then [ ./${x} ] else [ ])) [ ] (
          builtins.foldl' (
            acc: x:
            let
              split = builtins.elemAt splitFile x;
            in
            acc
            ++ builtins.foldl' (
              acc': x':
              let
                paths = [
                  "${x'}/${split}"
                  "${x'}/${split}/${prefix}"
                  "${x'}/${prefix}/${split}"
                ];
              in
              acc'
              ++ (
                if lib.hasSuffix ".nix" x' then
                  [ x' ]
                else
                  builtins.foldl' (
                    acc'': x'':
                    acc''
                    ++ lib.optionals (builtins.pathExists ./${x''}) [ x'' ]
                    ++ lib.optionals (
                      (x != splitLen - 1 || !splitLastIsNixFile) && builtins.pathExists ./${x''}/default.nix
                    ) [ "${x''}/default.nix" ]
                  ) [ ] paths
              )
            ) [ ] acc
          ) [ "/modules" ] (range (splitLen - 1))
        )
      );
      filePathsLen = builtins.length filePaths;
    in
    if filePathsLen == 0 then builtins.throw "Could not find module ${fileStr}" else filePaths;

  module =
    file:
    let
      foundModules = modules file;
      foundModulesLen = builtins.length foundModules;
    in
    if foundModulesLen == 1 then
      builtins.elemAt foundModules 0
    else
      abort (
        if foundModulesLen == 0 then
          "Module \"${file}\" not found"
        else
          "Ambiguous module \"${file}\": ${builtins.foldl' (acc: x: "${acc} \"${x}\"") "" foundModules}"
      );

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
