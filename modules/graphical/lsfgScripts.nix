pkgs: [
  (pkgs.writeShellScriptBin "lsfg1x" ''
    	  exec env LSFG_LEGACY=0 LSFG_PERFORMANCE_MODE=1 LSFG_MULTIPLIER=1 "$@"
    	'')
  (pkgs.writeShellScriptBin "lsfg2x" ''
    	  exec env LSFG_LEGACY=1 LSFG_PERFORMANCE_MODE=1 LSFG_MULTIPLIER=2 "$@"
    	'')
  (pkgs.writeShellScriptBin "lsfg3x" ''
    	  exec env LSFG_LEGACY=1 LSFG_PERFORMANCE_MODE=1 LSFG_MULTIPLIER=3 "$@"
    	'')
  (pkgs.writeShellScriptBin "lsfg4x" ''
    	  exec env LSFG_LEGACY=1 LSFG_PERFORMANCE_MODE=1 LSFG_MULTIPLIER=4 "$@"
    	'')
]
