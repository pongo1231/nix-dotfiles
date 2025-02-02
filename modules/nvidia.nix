{ platform }:
{
  inputs,
  patch,
  config,
  pkgs,
  lib,
  ...
}:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    package =
      (config.boot.kernelPackages.extend (
        finalAttrs: prevAttrs:
        let
          generic =
            args:
            finalAttrs.callPackage
              (import "${inputs.nixpkgs}/pkgs/os-specific/linux/nvidia-x11/generic.nix" args)
              { };
        in
        {
          nvidiaPackages.production =
            (generic {
              version = "570.86.16";
              sha256_64bit = "sha256-RWPqS7ZUJH9JEAWlfHLGdqrNlavhaR1xMyzs8lJhy9U=";
              openSha256 = "sha256-DuVNA63+pJ8IB7Tw2gM4HbwlOh1bcDg2AN2mbEU9VPE=";
              settingsSha256 = "sha256-9rtqh64TyhDF5fFAYiWl3oDHzKJqyOW3abpcf2iNRT8=";
              persistencedSha256 = "";

              patches = [
                (patch /nvidia/6.13/0003-FROM-AOSC-TTM-fbdev-emulation-for-Linux-6.13.patch)
                (patch /nvidia/6.14/comment-out-date.patch)
              ];
            }).overrideAttrs
              (
                finalAttrs': prevAttrs': {
                  # patched builder.sh to not include some egl libraries to prevent apps from blocking nvidia_drm unloading
                  builder = (patch /nvidia/builder.sh);

                  makeFlags = [
                    "IGNORE_PREEMPT_RT_PRESENCE=1"
                    "NV_BUILD_SUPPORTS_HMM=1"
                    "SYSSRC=${finalAttrs.kernel.dev}/lib/modules/${finalAttrs.kernel.modDirVersion}/source"
                    "SYSOUT=${finalAttrs.kernel.dev}/lib/modules/${finalAttrs.kernel.modDirVersion}/build"
                  ];

                  passthru = prevAttrs'.passthru // {
                    open = prevAttrs'.passthru.open.overrideAttrs (
                      finalAttrs'': prevAttrs'': {
                        patches = prevAttrs''.patches ++ [ ];

                        makeFlags = [
                          "SYSSRC=${finalAttrs.kernel.dev}/lib/modules/${finalAttrs.kernel.modDirVersion}/source"
                          "SYSOUT=${finalAttrs.kernel.dev}/lib/modules/${finalAttrs.kernel.modDirVersion}/build"
                          "MODLIB=$(out)/lib/modules/${finalAttrs.kernel.modDirVersion}"
                          {
                            aarch64-linux = "TARGET_ARCH=aarch64";
                            x86_64-linux = "TARGET_ARCH=x86_64";
                          }
                          .${finalAttrs.stdenv.hostPlatform.system}
                        ];
                      }
                    );
                  };
                }
              );
        }
      )).nvidiaPackages.production;

    modesetting.enable = true;
    open = true; # open kernel driver keeps dying frequently currently (failed to allocate vmap() page descriptor table!)
    prime =
      {
        offload.enable = true;
        nvidiaBusId = "PCI:1:0:0";
      }
      // lib.optionalAttrs (platform == "intel") { intelBusId = "PCI:0:2:0"; }
      // lib.optionalAttrs (platform == "amd") { amdgpuBusId = "PCI:5:0:0"; };
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    dynamicBoost.enable = true;
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "prime-run" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      # export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec -a "$0" "$@"
    '')
  ];
}
