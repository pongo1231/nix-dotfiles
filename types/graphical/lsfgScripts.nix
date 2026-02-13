pkgs: [
  (pkgs.writeShellScriptBin "lsfg1x" ''
    	  exec env DISABLE_LSFGVK=1 "$@"
    	'')
  (pkgs.writeShellScriptBin "lsfg2x" ''
    	  exec env LSFGVK_ENV=1 LSFGVK_PERFORMANCE_MODE=1 LSFGVK_MULTIPLIER=2 LSFGVK_FLOW_SCALE=0.85 "$@"
    	'')
  (pkgs.writeShellScriptBin "lsfg3x" ''
    	  exec env LSFGVK_ENV=1 LSFGVK_PERFORMANCE_MODE=1 LSFGVK_MULTIPLIER=3 LSFGVK_FLOW_SCALE=0.85 "$@"
    	'')
  (pkgs.writeShellScriptBin "lsfg4x" ''
    	  exec env LSFGVK_ENV=1 LSFGVK_PERFORMANCE_MODE=1 LSFGVK_MULTIPLIER=4 LSFGVK_FLOW_SCALE=0.85 "$@"
    	'')
]
