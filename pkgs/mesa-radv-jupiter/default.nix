{ mesa-radv-jupiter'
, fetchFromGitLab
}:

mesa-radv-jupiter'.overrideAttrs (finalAttrs: prevAttrs: {
  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "Mesa";
    repo = "mesa";
    rev = "5119e0adc3e3d0bbf3fa162b00d952d71d53c6fe";
    hash = "sha256-y+071dBbwDKurjWQumReYBBPzHHhWVC7CwcBDeB6i+Y=";
  };

  patches = prevAttrs.patches ++ [ ./25352.diff ];
})
