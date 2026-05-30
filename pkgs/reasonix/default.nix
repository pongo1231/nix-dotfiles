{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs-slim_latest,
}:
let
  src = fetchFromGitHub {
    owner = "esengine";
    repo = "DeepSeek-Reasonix";
    rev = "512e3dd66ef1936a7ca4737a9a7fc16ce02e907a";
    hash = "sha256-OBZgvjYRI+spUmG9OSXK/QG6DvmO6oZN62ZJmT10An0=";
  };

  nodeModules = stdenv.mkDerivation {
    name = "reasonix-node-modules";
    inherit src;

    outputHash = "sha256-KBTChJ1U0L2Wpv0OJdThrKqlvkg89W760Ovpu8JVV/s=";
    outputHashMode = "recursive";

    npm_config_cache = "/build/.npm";

    buildPhase = ''
      mkdir -p "$npm_config_cache"
      ${nodejs-slim_latest.npm}/bin/npm ci --ignore-scripts --legacy-peer-deps
    '';

    installPhase = ''
      mkdir -p $out
      cp -r node_modules $out/
    '';

    dontCheckForBrokenSymlinks = true;
  };

  mcpNodeModules = stdenv.mkDerivation {
    name = "reasonix-mcp-node-modules";

    outputHash = "sha256-IwaogI02P1Z2rcG0+77g+PL8Ncdd00ap685Dx5fzDnE=";
    outputHashMode = "recursive";

    npm_config_cache = "/build/.npm";

    dontUnpack = true;

    buildPhase = ''
            mkdir -p "$npm_config_cache"
            cat > package.json << 'PKGJSON'
      {
        "name": "reasonix-mcp-deps",
        "private": true,
        "dependencies": {
          "@modelcontextprotocol/server-filesystem": "2026.1.14",
          "@modelcontextprotocol/server-memory": "2026.1.26",
          "@modelcontextprotocol/server-github": "2025.4.8",
          "@modelcontextprotocol/server-puppeteer": "2025.5.12",
          "@modelcontextprotocol/server-everything": "2026.1.26"
        }
      }
      PKGJSON
            ${nodejs-slim_latest.npm}/bin/npm install --ignore-scripts --legacy-peer-deps
    '';

    installPhase = ''
      mkdir -p $out
      cp -r node_modules $out/
    '';

    dontCheckForBrokenSymlinks = true;
  };

  mcpBundledJson = builtins.toJSON {
    filesystem = "${mcpNodeModules}/node_modules/@modelcontextprotocol/server-filesystem/dist/index.js";
    memory = "${mcpNodeModules}/node_modules/@modelcontextprotocol/server-memory/dist/index.js";
    github = "${mcpNodeModules}/node_modules/@modelcontextprotocol/server-github/dist/index.js";
    puppeteer = "${mcpNodeModules}/node_modules/@modelcontextprotocol/server-puppeteer/dist/index.js";
    everything = "${mcpNodeModules}/node_modules/@modelcontextprotocol/server-everything/dist/index.js";
  };
in
stdenv.mkDerivation {
  pname = "reasonix";
  version = "git";

  inherit src;

  patches = [
    ./acp-improvements.patch
  ];

  postPatch = ''
        sed -i '/"postinstall"/d' package.json

        while IFS= read -r -d ''' file; do
          sed -i \
            -e 's/"strict": *true/"strict": false/g' \
            -e 's/"noImplicitAny": *true/"noImplicitAny": false/g' \
            -e 's/"skipLibCheck": *false/"skipLibCheck": true/g' \
            "$file"
        done < <(find . -name tsconfig.json -print0)

        sed -i 's/dts: true/dts: false/g' tsup.config.ts

        {
          sed -i '4a import { readFileSync } from "node:fs";' src/mcp/transport-from-spec.ts

          sed -i '/^export function buildTransportFromSpec/i\
    function resolveBundledMcp(command: string, args: string[]): { command: string; args: string[] } {\
      if (command !== "npx") return { command, args };\
      const pkgIdx = args.findIndex((a) => a.startsWith("@modelcontextprotocol/server-"));\
      if (pkgIdx < 0) return { command, args };\
      const pkgName = args[pkgIdx];\
      const serverName = pkgName.replace("@modelcontextprotocol/server-", "");\
      const bundledFile = process.env.REASONIX_MCP_BUNDLED;\
      if (!bundledFile) return { command, args };\
      try {\
        const bundled = JSON.parse(readFileSync(bundledFile, "utf8"));\
        if (bundled[serverName]) {\
          return {\
            command: process.execPath,\
            args: [bundled[serverName], ...args.slice(pkgIdx + 1)],\
          };\
        }\
      } catch { /* ignore */ }\
      return { command, args };\
    }\
    ' src/mcp/transport-from-spec.ts

          sed -i '/^  return new StdioTransport({/i\  const { command, args } = resolveBundledMcp(spec.command, spec.args);' src/mcp/transport-from-spec.ts

          sed -i '/^  return new StdioTransport({/,/^  });/{
            s/    command: spec.command,/    command,/
            s/    args: spec.args,/    args,/
          }' src/mcp/transport-from-spec.ts
        }
  '';

  configurePhase = ''
    cp -r ${nodeModules}/node_modules ./node_modules
    chmod -R u+w ./node_modules

    for link in $(find ./node_modules -maxdepth 2 -type l \( -lname "../../packages/*" -o -lname "../packages/*" \)); do
      target=$(readlink "$link")
      rm "$link"
      ln -sf "$target" "$link"
    done
  '';

  buildPhase =
    let
      node = "${nodejs-slim_latest}/bin/node";
    in
    ''
      ${node} node_modules/.bin/tsup
      ${node} scripts/copy-dashboard-vendor-css.mjs
      ${node} scripts/copy-tree-sitter-grammars.mjs
    '';

  installPhase = ''
        mkdir -p $out/lib/node_modules/reasonix $out/bin
        cp -r . $out/lib/node_modules/reasonix

        cat > $out/lib/node_modules/reasonix/mcp-bundled.json << 'BUNDLEDEOF'
        ${mcpBundledJson}
    BUNDLEDEOF

        cat > $out/bin/reasonix << WRAPPEREOF
    #!/bin/sh
    REASONIX_MCP_BUNDLED="$out/lib/node_modules/reasonix/mcp-bundled.json"
    export REASONIX_MCP_BUNDLED
    exec ${nodejs-slim_latest}/bin/node "$out/lib/node_modules/reasonix/dist/cli/index.js" "\$@"
    WRAPPEREOF
        chmod +x $out/bin/reasonix

        for name in filesystem memory github puppeteer everything; do
          echo '#!/bin/sh' > $out/bin/reasonix-mcp-$name
          echo "exec ${nodejs-slim_latest}/bin/node ${mcpNodeModules}/node_modules/@modelcontextprotocol/server-$name/dist/index.js \"\$@\"" >> $out/bin/reasonix-mcp-$name
          chmod +x $out/bin/reasonix-mcp-$name
        done
  '';

  meta = with lib; {
    description = "DeepSeek-native AI coding agent for your terminal";
    homepage = "https://github.com/esengine/DeepSeek-Reasonix";
    license = licenses.mit;
    mainProgram = "reasonix";
  };
}
