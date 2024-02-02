{ mesa-radv-jupiter'
, libdrm
, fetchFromGitLab
, fetchurl
}:

(mesa-radv-jupiter'.override {
  libdrm = libdrm.overrideAttrs (finalAttrs: prevAttrs: {
    version = "2.4.119";

    src = fetchurl {
      url = "https://dri.freedesktop.org/${finalAttrs.pname}/${finalAttrs.pname}-${finalAttrs.version}.tar.xz";
      hash = "sha256-CknxLwm1tuaOqq/z8Cynz/mqkmk5shLTQxYdPorFYpE=";
    };
  });
}).overrideAttrs (prevAttrs:
  let
    rev = "559f31e202fd8bdb984a6bbf8c03d65dd1e93d57";
  in
  {
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-nuTBiVR4sJ4Y/4t8BcTipyCg2n0Wr953ULau9xrzCPU=";
  };

  patches = prevAttrs.patches ++ [ ./25352.diff ];
})
