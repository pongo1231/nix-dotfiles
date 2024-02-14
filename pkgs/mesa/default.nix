{ mesa
, fetchFromGitLab
, fetchurl
, fetchpatch
}:

mesa.overrideAttrs (prevAttrs:
let
  rev = "5178ad761c9e8e86ffb3bc59322ec998c0ae2063";
in
{
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-JcNXhSsjC3oI5efOkDHG4P9BVshFIajoui8EaoAYr7M=";
  };

  patches = prevAttrs.patches ++ [
    (fetchpatch {
      url = "https://github.com/Jovian-Experiments/mesa/commit/9ca7d7775f34bca9578306b139ddd03e4f176e01.patch";
      hash = "sha256-dVqt0x0yDyNfpBKOo/tRk8394PPVOooNTpCLsFqZwUE=";
    })

    ./25352.diff
  ];
})
