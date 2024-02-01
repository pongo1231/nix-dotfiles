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
    rev = "1d1a7f9d566ddcf423300fbb7bb203c32f973a84";
  in
  {
  version = "git-${builtins.substring 0 6 rev}";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    inherit rev;
    hash = "sha256-plsfVh2O1bIpG1lNqgVglM6NZ8LZ4/Re9mp2Goxhb6s=";
  };

  patches = prevAttrs.patches ++ [ ./25352.diff ];
})
