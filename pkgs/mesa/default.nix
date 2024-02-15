{ lib
, mesa
, libclc
, llvmPackages
, fetchFromGitLab
, fetchurl
, fetchpatch
}:

(mesa.override {
  galliumDrivers = [
    "iris"
    "i915"
    "radeonsi"
    "swrast"
  ];
  vulkanDrivers = [
    "intel"
    "amd"
    "swrast"
  ];
  enableGalliumNine = false;
  enableOpenCL = true;
}).overrideAttrs (prevAttrs:
let
  rev = "90eae30bcb84d54dc871ddbb8355f729cf8fa900";
in
{
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-EJihKqmLHJmIgRpKx5lTTDlFoT5jCEFLQlJYTYifJLY=";
  };

  patches = (builtins.filter (x: !lib.strings.hasInfix "000" x /* skip macOS backports */) prevAttrs.patches) ++ [
    (fetchpatch {
      url = "https://github.com/Jovian-Experiments/mesa/commit/9ca7d7775f34bca9578306b139ddd03e4f176e01.patch";
      hash = "sha256-dVqt0x0yDyNfpBKOo/tRk8394PPVOooNTpCLsFqZwUE=";
    })

    ./25352.diff
  ];
})
