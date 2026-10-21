{
  gnomeExtensions,
  patch,
}:
(gnomeExtensions.appindicator.override {
  uuid = "appindicator-tooltip@local";
}).overrideAttrs
  (prev: {
    patches = [
      (patch /appindicator/tooltip.patch)
    ];

    patchFlags = [
      "-p1"
      "--fuzz=0"
    ];

    postPatch = ''
      grep -v '"_generated"' metadata.json > metadata.json.new
      mv metadata.json.new metadata.json
      substituteInPlace metadata.json \
        --replace-fail '"name": "AppIndicator and KStatusNotifierItem Support"' '"name": "AppIndicator and KStatusNotifierItem Support (patched)"' \
        --replace-fail '"uuid": "appindicatorsupport@rgcjonas.gmail.com"' '"uuid": "appindicator-tooltip@local"'
    '';
  })
