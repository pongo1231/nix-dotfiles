{ mesa-radv-jupiter'
, fetchFromGitLab
}:

mesa-radv-jupiter'.overrideAttrs (finalAttrs: prevAttrs: {
  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    rev = "3b715fb99dee536683bcfbbdbdb4b7b71816da13";
    hash = "sha256-DZmDpA0zZWIpl45M3FmW5gnQIXHZns87llhxS9UxOk4=";
  };

  patches = prevAttrs.patches ++ [ ./25352.diff ];
})
