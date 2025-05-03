{
  patch,
  pkg,
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
      (final: prev: {
        linuxPackages_pongo = final.linuxPackages_testing.extend (
          finalAttrs: prevAttrs: {
            kernel =
              (prevAttrs.kernel.override (prevAttrs': {
                /*
                  stdenv = pkgs.llvmPackages.stdenv.override (prevAttrs'': {
                    cc = prevAttrs''.cc.override {
                      bintools = pkgs.llvmPackages.bintools;
                      extraBuildCommands = ''
                                        substituteInPlace "$out/nix-support/cc-cflags" --replace-fail " -nostdlibinc" ""
                        				  echo " -resource-dir=${pkgs.llvmPackages.libclang.lib}/lib/clang/${lib.versions.major pkgs.llvmPackages.libclang.version}" >> $out/nix-support/cc-cflags
                        				  '';
                    };
                  });
                */

                #stdenv = final.ccacheStdenv;
                #kernelPatches = builtins.filter (x: !lib.hasPrefix "netfilter-typo-fix" x.name) prevAttrs'.kernelPatches;
                ignoreConfigErrors = true;
                argsOverride =
                  let
                    version = "6.15.0-rc4";
                  in
                  {
                    inherit version;
                    modDirVersion = "6.15.0-rc4";
                    src = final.fetchFromGitHub {
                      owner = "pongo1231";
                      repo = "linux";
                      rev = "7b217616745018ac5e30296f0947fa3b65928e80";
                      hash = "sha256-CmAu0FByYzA5JOa3VbyU9vsMGtwRHsQHkQUpucKrKw4=";
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
              })).overrideAttrs
                (
                  finalAttrs': prevAttrs': {
                    #hardeningDisable = [ "strictoverflow" ];
                  }
                );

            xpadneo = prevAttrs.xpadneo.overrideAttrs (
              finalAttrs': prevAttrs': {
                src = final.fetchFromGitHub {
                  owner = "atar-axis";
                  repo = "xpadneo";
                  rev = "8d20a23e38883f45c78f48c8574ac93945b4cb03";
                  hash = "sha256-u54EX8z/zRXUN+pPOLwENdESunU/J0Lj1OpMj/1EVq4=";
                };

                patches = [ ];

                makeFlags = [
                  "-C"
                  "${finalAttrs.kernel.dev}/lib/modules/${finalAttrs.kernel.modDirVersion}/build"
                  "M=$(sourceRoot)"
                  "VERSION=${finalAttrs'.version}"
                  #"LLVM=1"
                ];

                #hardeningDisable = [ "strictoverflow" ];
              }
            );
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
        # cachyos settings
        "kernel.sched_burst_cache_lifetime" = 60000000;
        "kernel.sched_burst_penalty_offset" = 22;

        "kernel.sched_burst_exclude_kthreads" = 0;
        "vm.workingset_protection" = 0;
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
