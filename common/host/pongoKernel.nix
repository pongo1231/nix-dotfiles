{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.pongo.pongoKernel;
in
{
  options.pongo.pongoKernel = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    crossCompile = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        linuxPackages_pongo =
          let
            pkgs' = if cfg.crossCompile != null then pkgs.pkgsCross.${cfg.crossCompile.target} else pkgs;
          in
          pkgs'.linuxPackages_testing.extend (
            final': prev': {
              kernel =
                let
                  llvm = pkgs'.llvmPackages_latest;
                  llvmTools = llvm.llvm;
                in
                prev'.kernel.override {
                  buildPackages = pkgs'.buildPackages // {
                    inherit (llvm) stdenv;
                  };

                  inherit (llvm) stdenv;
                  inherit (pkgs') pkgsBuildBuild;

                  ignoreConfigErrors = true;

                  extraMakeFlags = [
                    "LLVM=1"
                    "CC=${llvm.clang-unwrapped}/bin/clang"
                    "LD=${llvm.lld}/bin/ld.lld"
                    "AR=${llvmTools}/bin/llvm-ar"
                    "NM=${llvmTools}/bin/llvm-nm"
                    "STRIP=${llvmTools}/bin/llvm-strip"
                    "OBJCOPY=${llvmTools}/bin/llvm-objcopy"
                    "OBJDUMP=${llvmTools}/bin/llvm-objdump"
                    "READELF=${llvmTools}/bin/llvm-readelf"
                  ];

                  argsOverride =
                    let
                      version = "7.1-git";
                    in
                    {
                      inherit version;
                      modDirVersion = "7.0.0";
                      src = final.fetchFromGitHub {
                        owner = "torvalds";
                        repo = "linux";
                        rev = "da6b5aae84beb0917ecb0c9fbc71169d145397ff";
                        hash = "sha256-rXF7gEzLfSqnH9+VaG0dFPj31zISXG863cVOaGwcqiU=";
                      };
                    };
                };
            }
          );
      })
    ];

    boot = {
      kernelPackages = pkgs.linuxPackages_pongo;

      kernelPatches = [
        {
          name = "base";
          patch = null;
          extraConfig = ''
            BTRFS_EXPERIMENTAL y
            LTO_CLANG_THIN y
            CFI y
            UBSAN y
            UBSAN_TRAP y
            UBSAN_BOUNDS y
            UBSAN_BOOL n
            UBSAN_ENUM n
          '';
        }
        /*
          {
            name = "AMD_PRIVATE_COLOR";
            patch = pkgs.fetchpatch {
              url = "https://github.com/CachyOS/linux/commit/458baffc0f15d5270f41f0d1b5e8a771b5c3c69a.patch";
              hash = "sha256-fLBWF1x9e9J8qMy5cZdejlEHPi0iUaSgVkrG4x3b5jg=";
            };
            extraConfig = lib.optionalString (pkgs.stdenv.hostPlatform.system == "x86_64-linux") ''
              AMD_PRIVATE_COLOR y
            '';
          }
        */
        {
          name = "O3";
          patch = pkgs.fetchpatch {
            url = "https://github.com/CachyOS/linux/commit/c24fe6d7154676e8df601e3ae54072032899f562.patch";
            hash = "sha256-pHAjHrseUs5xEmNSqgBmTZlC0mb8cMHuYvMRzFvlxQ4=";
          };
          extraConfig = ''
            CC_OPTIMIZE_FOR_PERFORMANCE_O3 y
          '';
        }
        {
          name = "x86_64 levels";
          patch = pkgs.fetchpatch {
            url = "https://github.com/CachyOS/linux/commit/b24e97ea653f29ffa815221e4e5a60cc51e61c24.patch";
            hash = "sha256-05q30EQmS+EUL/DTeDVefGAMf+0zfNueJ5aEIyN4OU0=";
          };
          extraConfig = lib.optionalString (pkgs.stdenv.hostPlatform.system == "x86_64-linux") ''
            X86_64_VERSION 3
          '';
        }
      ];
    };
  };
}
