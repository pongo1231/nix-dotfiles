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
      filePaths = builtins.foldl' (acc: x: acc ++ [ ./${x} ]) [ ] (
        builtins.foldl' (
          acc: x:
          let
            split = builtins.elemAt splitFile x;
          in
          builtins.foldl' (
            acc': x':
            let
              paths = [
                "${x'}/${split}"
                "${x'}/${split}/${prefix}"
                "${x'}/${prefix}/${split}"
              ];
            in
            acc'
            ++ builtins.foldl' (
              acc'': x'':
              if
                (builtins.pathExists (
                  ./. + "${x''}${if (x != splitLen - 1 || splitLastIsNixFile) then "" else "/default.nix"}"
                ))
              then
                acc'' ++ [ x'' ]
              else
                acc''
            ) [ ] paths
          ) [ ] acc
        ) [ "/modules" ] (range (splitLen - 1))
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
    if foundModulesLen == 1 then builtins.elemAt foundModules 0 else _: { imports = foundModules; };

  patch = file: ./patches/${file};
  pkg = file: ./pkgs/${file};

  withSecrets =
    user:
    {
      store ? "default",
      owner ? null,
      group ? null,
    }:
    secrets: {
      sops.secrets = lib.mapAttrs' (name: value: {
        inherit name;
        value =
          {
            sopsFile = ./secrets/${user}/${value.store or store}.yaml;
          }
          // lib.optionalAttrs (owner != null) { inherit owner; }
          // lib.optionalAttrs (group != null) {
            inherit group;
            mode = "0440";
          }
          // builtins.removeAttrs value [ "store" ];
      }) secrets;
    };

  private = file: ./private/${file};
}
// builtins.removeAttrs args [
  "prefix"
  "lib"
]
