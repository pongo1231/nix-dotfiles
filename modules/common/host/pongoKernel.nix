{
  patch,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.pongo;
in
{
  options.pongo.pongoKernel.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };

  config = lib.mkIf cfg.pongoKernel.enable {
    nixpkgs.overlays = [
      (final: _: {
        linuxPackages_pongo = final.linuxPackages_testing.extend (
          _: prev': {
            kernel =
              (prev'.kernel.override {
                /*
                  stdenv = pkgs.llvmPackages.stdenv.override (prev'': {
                    cc = prev''.cc.override {
                      bintools = pkgs.llvmPackages.bintools;
                      extraBuildCommands = ''
                                        substituteInPlace "$out/nix-support/cc-cflags" --replace-fail " -nostdlibinc" ""
                        				  echo " -resource-dir=${pkgs.llvmPackages.libclang.lib}/lib/clang/${lib.versions.major pkgs.llvmPackages.libclang.version}" >> $out/nix-support/cc-cflags
                        				  '';
                    };
                  });
                */

                #kernelPatches = builtins.filter (x: !lib.hasPrefix "netfilter-typo-fix" x.name) prev'.kernelPatches;

                #ignoreConfigErrors = true;

                argsOverride =
                  let
                    version = "6.16.0-git";
                  in
                  {
                    inherit version;
                    modDirVersion = "6.16.0-rc7";
                    src = final.fetchFromGitHub {
                      owner = "pongo1231";
                      repo = "linux";
                      rev = "8187ec0d77e61c66d1be25a5ce174e97bb539282";
                      hash = "sha256-3S4AeLRI2kctAvMiYC8A9CifaXSMgqkyU0/HpeKZun4=";
                    };

                    #src = final.fetchzip {
                    #    url = "https://git.kernel.org/torvalds/t/linux-${version}.tar.gz";
                    #    hash = "";
                    # };

                    /*
                      extraMakeFlags = [
                        "LLVM=1"
                        "LLVM_IAS=1"
                      ];

                      extraConfig = ''
                        CC_IS_CLANG y
                        LTO_CLANG y
                        LTO_CLANG_THIN y
                        LTO_CLANG_THIN_DIST y
                      '';
                    */
                  };
              }).overrideAttrs
                (_: {
                  #hardeningDisable = [ "strictoverflow" ];
                });

            xpadneo = prev'.xpadneo.overrideAttrs {
              src = final.fetchFromGitHub {
                owner = "atar-axis";
                repo = "xpadneo";
                rev = "cd256807c5f916735ae18749c43d5b0bd73240fa";
                hash = "sha256-TLtxpDYxatPV5VBssFX4kriEVy/GrQpq33j3/dVGxuE=";
              };

              #makeFlags = prev''.makeFlags ++ [ "LLVM=1" ];

              #hardeningDisable = [ "strictoverflow" ];
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

      kernel.sysctl = {
        #"vm.anon_min_ratio" = 15;
        #"vm.clean_low_ratio" = 15;
        #"vm.clean_min_ratio" = 1;
      };
    };

    services.udev.extraRules = ''
      # set scheduler for NVMe
      ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="adios"
      # set scheduler for SSD and eMMC
      ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="adios"
      # set scheduler for rotating disks
      ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="adios"
    '';
  };
}
