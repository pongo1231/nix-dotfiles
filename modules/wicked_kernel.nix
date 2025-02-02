{
  patch,
  pkg,
  pkgs,
  lib,
  ...
}:
{
  nixpkgs.overlays = [
    (final: prev: {
      linuxPackages_wicked = final.kernel.linuxPackages_latest.extend (
        finalAttrs: prevAttrs: {
          /*
            kernel =
            (prevAttrs.kernel.override (prevAttrs': {
              #stdenv = final.ccacheStdenv;
              #kernelPatches = builtins.filter (x: !lib.hasPrefix "netfilter-typo-fix" x.name) prevAttrs'.kernelPatches;
              ignoreConfigErrors = true;
              argsOverride =
                let
                  version = "6.14-git";
                in
                {
                  inherit version;
                  modDirVersion = "6.13.0";
                  src = final.fetchgit {
                    url = "https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git";
                    rev = "6d61a53dd6f55405ebcaea6ee38d1ab5a8856c2c";
                    hash = "sha256-4DEDOMSdREL6qbS52CFXKXXJF8iRTviN8UZozh5YYUU=";
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
          */

          xpadneo = prevAttrs.xpadneo.overrideAttrs (
            finalAttrs': prevAttrs': {
              src = final.fetchFromGitHub {
                owner = "atar-axis";
                repo = "xpadneo";
                rev = "227c101fea112e8b7309aadb736b9a1c4120b126";
                hash = "sha256-fI6gX2p2RaJdKi8bluGjqryg0Zjv8otvDe0Fph72mMw=";
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
    kernelPackages =
      let
        stdenvLLVM =
          let
            llvmPin = pkgs.buildPackages.llvmPackages.override (prevAttrs: {
              bootBintools = null;
              bootBintoolsNoLibc = null;
            });
            stdenv' = pkgs.overrideCC llvmPin.stdenv llvmPin.clangUseLLVM;
          in
          stdenv'
          // {
            mkDerivation =
              args:
              stdenv'.mkDerivation (
                args
                // {
                  nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ (with llvmPin; [ lld ]);
                }
              );
          };
        makeLTO =
          p:
          p.extend (
            finalAttrs: prevAttrs: {
              kernel = prevAttrs.kernel.override (prevAttrs': {
                stdenv = stdenvLLVM;
                extraMakeFlags = prevAttrs.kernel.extraMakeFlags ++ [
                  "LLVM=1"
                  "LLVM_IAS=1"
                  "KBUILD_CFLAGS=-Wno-error=unused-command-line-argument"
                ];
                argsOverride.structuredExtraConfig = prevAttrs.kernel.structuredExtraConfig // {
                  LTO_NONE = lib.kernel.no;
                  LTO_CLANG_FULL = lib.kernel.yes;
                };
              });
            }
          );
      in
      # makeLTO
      pkgs.linuxPackages_wicked;

    kernelPatches = [
      {
        name = "base";
        patch = patch /linux/6.14/base.patch;
        extraConfig = ''
          AMD_PRIVATE_COLOR y
          X86_64_VERSION 3
          CC_OPTIMIZE_FOR_PERFORMANCE_O3 y
          #PT_RECLAIM y
          #MHP_DEFAULT_ONLINE_TYPE_ONLINE_AUTO y
          LEDS_STEAMDECK m
          EXTCON_STEAMDECK m
          MFD_STEAMDECK m
          SENSORS_STEAMDECK m
        '';
      }
    ];

    kernel.sysctl = {
      # cachyos settings
      "kernel.sched_burst_cache_lifetime" = 60000000;
      "kernel.sched_burst_penalty_offset" = 22;
    };
  };
}
