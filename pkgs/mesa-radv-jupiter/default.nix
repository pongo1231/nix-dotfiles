{ mesa-radv-jupiter'
, fetchFromGitLab
}:

mesa-radv-jupiter'.overrideAttrs (finalAttrs: prevAttrs: {
  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    rev = "c511b8968a28c0c98a36500f68881cde0d2104bd";
    hash = "sha256-Xe+PRr/cRwXuBkCtaIoyhdc+A60XwXwNAmD8QnI03eM=";
  };

  patches = prevAttrs.patches ++ [ ./25352.diff ];
})
