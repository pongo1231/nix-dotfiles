{
  gnomeExtensions,
  patch,
}:
(gnomeExtensions.dash-to-panel.override {
  uuid = "dash-to-panel-patched@local";
}).overrideAttrs
  (prev: {
    patches = [
      (patch /dash-to-panel/audio.patch)
    ];

    patchFlags = [
      "-p1"
      "--fuzz=0"
    ];

    postPatch = ''
      grep -v '"_generated"' metadata.json > metadata.json.new
      mv metadata.json.new metadata.json
      substituteInPlace metadata.json \
        --replace-fail '"name": "Dash to Panel"' '"name": "Dash to Panel (patched)"' \
        --replace-fail '"uuid": "dash-to-panel@jderose9.github.com"' '"uuid": "dash-to-panel-patched@local"'
    '';
  })
