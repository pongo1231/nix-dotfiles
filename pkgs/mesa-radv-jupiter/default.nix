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
    rev = "2fa1979c6688b92917e6242bab7e5c08ec8831b4";
    hash = "sha256-uHM+c3s7fNZXWDTmzYrhm6hx5/Obr1li4qb/ximi/rY=";
  };

  patches = prevAttrs.patches ++ [ ./25352.diff ];
})
