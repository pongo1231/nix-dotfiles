{
  prefix,
  isNixosModule,
  inputs,
  lib,
  ...
}@args:
{
  configInfo = {
    type = prefix;
    inherit isNixosModule;
  };

  module =
    file:
    let
      fileStr = builtins.toString file;
      splitFile = lib.splitString "/" fileStr;
      splitLen = builtins.length splitFile;
      splitLastIsNixFile = lib.hasSuffix ".nix" (builtins.elemAt splitFile (splitLen - 1));
      filePath =
        let
          filePaths =
            let
              range = x: if x < 1 then [ ] else range (x - 1) ++ [ x ];
            in
            lib.unique (
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
        if (filePathsLen == 0) then
          builtins.throw "Could not find module ${fileStr}"
        else if (filePathsLen > 1) then
          builtins.throw "Ambiguous module ${fileStr} (found following paths:${
            builtins.foldl' (acc: x: "${acc} ${x}") "" filePaths
          })"
        else
          ./${builtins.elemAt filePaths 0};
    in
    filePath;

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
            sopsFile = ./secrets/${user}/${if value ? store then value.store else store}.yaml;
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
