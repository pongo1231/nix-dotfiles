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
        linuxPackages_pongo = final.kernel.linuxPackages_testing.extend (
          finalAttrs: prevAttrs: {
            kernel =
              (prevAttrs.kernel.override (prevAttrs': {
                #stdenv = final.ccacheStdenv;
                #kernelPatches = builtins.filter (x: !lib.hasPrefix "netfilter-typo-fix" x.name) prevAttrs'.kernelPatches;
                ignoreConfigErrors = true;
                argsOverride =
                  let
                    version = "6.15.0-rc3";
                  in
                  {
                    inherit version;
                    modDirVersion = "6.15.0-rc3";
                    src = final.fetchFromGitHub {
                      owner = "pongo1231";
                      repo = "linux";
                      rev = "412554819ea7e8c9af90b14a89530314c2904e74";
                      hash = "sha256-Gp3Wl76gPq0siA6nbp0Dq+UxaoNi67B6kkEEnOm3DBg=";
                    };
                    #src = final.fetchzip {
                    #    url = "https://git.kernel.org/torvalds/t/linux-${version}.tar.gz";
                    #    hash = "";
                    # };
                  };
              })).overrideAttrs
                (
                  finalAttrs': prevAttrs': {
                    #depsBuildBuild = [ final.ccacheStdenv ];
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
                ];
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
          #patch = patch /linux/6.14/base.patch;
          patch = null;
          extraConfig = ''
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
