{
  prefix,
  system,
  inputs,
  lib,
  ...
}@args:
{
  module =
    file:
    let
      fileStr = builtins.toString file;
      splitFile = lib.splitString "/" fileStr;
      splitLen = builtins.length splitFile;
      splitGet = index: {
        elem = builtins.elemAt splitFile index;
        excludeElem =
          let
            before = lib.sublist 0 index splitFile;
            after = lib.sublist (index + 1) (splitLen - index - 1) splitFile;
          in
          before ++ after;
      };
      filePath =
        let
          range = x: if x < 1 then [ ] else range (x - 1) ++ [ x ];
        in
        builtins.foldl' (
          acc: x:
          let
            split = splitGet x;
            prefixLast =
              ./. + "modules${lib.foldl' (acc: x: acc + "/${x}") "" split.excludeElem}/${prefix}/${split.elem}";
            prefixFirst =
              ./. + "modules/${split.elem}/${prefix}${lib.foldl' (acc: x: acc + "/${x}") "" split.excludeElem}";
          in
          if (builtins.pathExists prefixLast) then
            prefixLast
          else if (builtins.pathExists prefixFirst) then
            prefixFirst
          else
            acc
        ) "/" (range (splitLen - 1));
    in
    if (splitLen > 1 && builtins.pathExists filePath) then
      filePath
    else if (builtins.pathExists ./modules/${file}/${prefix}) then
      ./modules/${file}/${prefix}
    else if (builtins.pathExists ./modules/${prefix}/${file}) then
      ./modules/${prefix}/${file}
    else
      ./modules/${file};

  patch = file: ./patches/${file};
  pkg = file: ./pkgs/${file};

  withSecrets =
    user:
    {
      owner ? null,
      group ? null,
    }:
    secrets: {
      sops.secrets = lib.mapAttrs' (name: value: {
        inherit name;
        value =
          {
            sopsFile = ./secrets/${user}/secrets.yaml;
          }
          // lib.optionalAttrs (owner != null) { inherit owner; }
          // lib.optionalAttrs (group != null) {
            inherit group;
            mode = "0440";
          }
          // value;
      }) secrets;
    };

  private = file: ./private/${file};
}
// builtins.removeAttrs args [ "lib" ]
