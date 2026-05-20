{
  lib,
  rolesDir ? ./roles,
}:
let
  isMergeableAttrs = value: builtins.isAttrs value && !(lib.isDerivation value);

  mergeInfo =
    lhs: rhs:
    lib.zipAttrsWith
      (
        _name: values:
        if builtins.all isMergeableAttrs values then
          mergeInfos values
        else if builtins.all builtins.isList values then
          lib.unique (lib.concatLists values)
        else
          lib.last values
      )
      [
        lhs
        rhs
      ];

  mergeInfos = lib.foldl' mergeInfo { };

  rolePrefixes =
    role:
    let
      parts = builtins.filter (part: part != "") (lib.splitString "/" (builtins.toString role));
    in
    builtins.genList (i: lib.concatStringsSep "/" (lib.take (i + 1) parts)) (builtins.length parts);

  roleInfoPaths =
    role:
    builtins.filter builtins.pathExists (
      map (prefix: rolesDir + "/${prefix}/info.nix") (rolePrefixes role)
    );

  roleInfos = role: map import (roleInfoPaths role);

  collectRoles =
    seen: roles:
    builtins.foldl'
      (
        acc: role:
        if builtins.elem role acc.seen then
          acc
        else
          let
            infos = roleInfos role;
            info = mergeInfos infos;
            nested = collectRoles (acc.seen ++ [ role ]) (info.roles or [ ]);
          in
          {
            seen = nested.seen;
            roles = acc.roles ++ nested.roles ++ [ role ];
            infos = acc.infos ++ nested.infos ++ infos;
          }
      )
      {
        inherit seen;
        roles = [ ];
        infos = [ ];
      }
      roles;
in
{
  inherit mergeInfo mergeInfos roleInfos;

  rolesInfo =
    roles:
    let
      resolved = collectRoles [ ] roles;
    in
    {
      roles = lib.unique resolved.roles;
      infos = resolved.infos;
      info = mergeInfos resolved.infos;
    };
}
