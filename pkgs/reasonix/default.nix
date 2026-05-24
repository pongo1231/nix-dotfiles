{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:

buildNpmPackage rec {
  pname = "reasonix";
  version = "0.50.1";

  src = fetchFromGitHub {
    owner = "esengine";
    repo = "DeepSeek-Reasonix";
    rev = "v${version}";
    hash = "sha256-oLIx2ePC2jDvOqPwO+gnllZOtL3Nr9Rv7VI/b7N3qcw=";
  };

  npmDepsHash = "sha256-Dtp6OjsDzVVDPmuRdjhhpLIv9SLhE3XUcA3ZLg+nS6s=";

  npmWorkspaces = true;

  postPatch = ''
    sed -i '/"postinstall"/d' package.json

    while IFS= read -r -d ''' file; do
      echo "Patching $file"
      sed -i 's/"strict": *true/"strict": false/g' "$file"
      if grep -q '"noImplicitAny"' "$file"; then
        sed -i 's/"noImplicitAny": *true/"noImplicitAny": false/g' "$file"
      else
        if grep -q '"compilerOptions"' "$file"; then
          sed -i 's/"compilerOptions": *{/"compilerOptions": {\n    "noImplicitAny": false,/' "$file"
        fi
      fi
      if grep -q '"skipLibCheck"' "$file"; then
        sed -i 's/"skipLibCheck": *false/"skipLibCheck": true/g' "$file"
      else
        sed -i 's/"compilerOptions": *{/"compilerOptions": {\n    "skipLibCheck": true,/' "$file"
      fi
    done < <(find . -name tsconfig.json -print0)

    sed -i 's/"build": ".*"/"build": "tsup \&\& node scripts\/copy-dashboard-vendor-css.mjs \&\& node scripts\/copy-tree-sitter-grammars.mjs"/' package.json

    sed -i 's/dts: true/dts: false/g' tsup.config.ts
  '';

  npmRebuildFlags = [ "--ignore-scripts" ];

  dontCheckForBrokenSymlinks = true;

  meta = with lib; {
    description = "DeepSeek-native AI coding agent for your terminal";
    homepage = "https://github.com/esengine/DeepSeek-Reasonix";
    license = licenses.mit;
    mainProgram = "reasonix";
  };
}
