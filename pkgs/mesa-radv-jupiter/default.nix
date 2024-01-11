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
    rev = "c31be1f4bacde88ccd7177af26cb554c35472573";
    hash = "sha256-quePEV37HJOSVWun90dkteO0r5yuxnDLmcfZlZ5lYUA=";
  };

  patches = prevAttrs.patches ++ [ ./25352.diff ];
})
