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
}).overrideAttrs (prevAttrs: {
  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    rev = "fa1c9618f970ffd5e1ddf1fc0a4783bbee1d911e";
    hash = "sha256-0EbYC4RKPMqp4otvoBF0Qe/iA8e4B8+ForiQ+YRVMNg=";
  };

  patches = prevAttrs.patches ++ [ ./25352.diff ];
})
