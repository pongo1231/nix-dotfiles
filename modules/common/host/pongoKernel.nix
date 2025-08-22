{
  inputs,
  system,
  patch,
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
      default = false;
    };

    crossCompile = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: _: {
        linuxPackages_pongo =
          (
            if cfg.crossCompile != null then
              inputs.nixpkgs2.legacyPackages.${cfg.crossCompile.host}.pkgsCross.${cfg.crossCompile.target}.linuxPackages_testing
            else
              inputs.nixpkgs2.legacyPackages.${system}.linuxPackages_testing
          ).extend
            (
              let
                pkgs' =
                  if cfg.crossCompile != null then
                    inputs.nixpkgs2.legacyPackages.${cfg.crossCompile.host}.pkgsCross.${cfg.crossCompile.target}
                  else
                    inputs.nixpkgs2.legacyPackages.${system};
              in
              final': prev': {
                kernel =
                  let
                    stdenv = pkgs'.llvmPackages_latest.stdenv.override {
                      cc = pkgs'.llvmPackages_latest.clang.override {
                        bintools = pkgs'.llvmPackages_latest.bintools;
                        extraBuildCommands = ''
                          substituteInPlace $out/nix-support/cc-cflags --replace-fail " -nostdlibinc" ""
                          sed -i "1s;^;-B${pkgs'.llvmPackages_latest.libclang.lib}/lib -B${pkgs'.llvmPackages_latest.libclang.lib}/lib/clang/${lib.versions.major pkgs'.llvmPackages_latest.libclang.version} -resource-dir=${pkgs'.llvmPackages_latest.libclang.lib}/lib/clang/${lib.versions.major pkgs'.llvmPackages_latest.libclang.version} ;" $out/nix-support/cc-cflags
                        '';
                      };
                    };
                  in
                  (prev'.kernel.override {
                    buildPackages = pkgs'.buildPackages // {
                      inherit stdenv;
                    };

                    inherit stdenv;

                    ignoreConfigErrors = true;

                    argsOverride =
                      let
                        version = "6.17.0-git";
                      in
                      {
                        inherit version;
                        modDirVersion = "6.17.0-rc2";
                        src = final.fetchFromGitHub {
                          owner = "pongo1231";
                          repo = "linux";
                          rev = "fdea3747841cf67ab95a45cd3f4214b948de881d";
                          hash = "sha256-YAMQu0NwXwkEZQ3bb+HMjeOOHggQLNKgDzP5QL0m2DY=";
                        };

                        extraMakeFlags = [
                          "LLVM=1"
                        ];

                        extraConfig = ''
                          LTO_CLANG y
                          LTO_CLANG_THIN y
                          LTO_CLANG_THIN_DIST y
                        '';
                      };
                  }).overrideAttrs
                    (_: {
                      hardeningDisable = [
                        "strictoverflow"
                        "zerocallusedregs"
                      ];
                    });

                xpadneo = prev'.xpadneo.overrideAttrs (prev'': {
                  src = final.fetchFromGitHub {
                    owner = "atar-axis";
                    repo = "xpadneo";
                    rev = "a16acb03e7be191d47ebfbc8ca1d5223422dac3e";
                    hash = "sha256-4eOP6qAkD7jGOqaZPOB5/pdoqixl2Jy2iSVvK2caE80=";
                  };

                  makeFlags = prev''.makeFlags ++ [ "LLVM=1" ];

                  hardeningDisable = [ "strictoverflow" ];
                });
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
            CC_OPTIMIZE_FOR_PERFORMANCE_O3 y
            BTRFS_EXPERIMENTAL y
            PREEMPT_DYNAMIC y
          ''
          + lib.optionalString (system == "x86_64-linux") ''
            X86_64_VERSION 3
            AMD_PRIVATE_COLOR y
            LEDS_STEAMDECK m
            EXTCON_STEAMDECK m
            MFD_STEAMDECK m
            SENSORS_STEAMDECK m
          '';
        }
      ];

      kernelModules = [ "adios" ];
    };

    services.udev.extraRules = ''
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]|sd[a-z]*|mmcblk[0-9]*", ATTR{queue/scheduler}="adios"
    '';
  };
}
