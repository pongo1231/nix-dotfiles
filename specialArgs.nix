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
      pathPrefixLast =
        let
          split = splitGet (splitLen - 1);
        in
        ./. + "/modules${lib.foldl' (acc: x: acc + "/${x}") "" split.excludeElem}/${prefix}/${split.elem}";
      pathPrefixFirst =
        let
          split = splitGet 0;
        in
        ./. + "/modules/${split.elem}/${prefix}${lib.foldl' (acc: x: acc + "/${x}") "" split.excludeElem}";
    in
    if (splitLen > 1 && builtins.pathExists pathPrefixLast) then
      pathPrefixLast
    else if (splitLen > 1 && builtins.pathExists pathPrefixFirst) then
      pathPrefixFirst
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
