{ mesa-radv-jupiter'
, fetchFromGitLab
}:

mesa-radv-jupiter'.overrideAttrs (finalAttrs: prevAttrs: {
  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    rev = "6a810b0ba82384d2cdaee94e8019e57b96cff700";
    hash = "sha256-wJImip1kIZWIiDIpvBFj3NPDkI09nsSE+pbtzJBuJ2A=";
  };

  patches = prevAttrs.patches ++ [ ./25352.diff ];
})
