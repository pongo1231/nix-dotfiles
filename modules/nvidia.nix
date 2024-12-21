{ platform }:
{ inputs
, patch
, config
, pkgs
, lib
, ...
}:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  /*boot.extraModprobeConfig = ''
    options nvidia NVreg_EnableGpuFirmware=0
  '';*/

  hardware.nvidia = {
    package = (config.boot.kernelPackages.extend
      (finalAttrs: prevAttrs:
        let generic = args: finalAttrs.callPackage (import "${inputs.nixpkgs}/pkgs/os-specific/linux/nvidia-x11/generic.nix" args) { };
        in {
          nvidiaPackages.production = (generic {
            version = "565.77";
            sha256_64bit = "sha256-CnqnQsRrzzTXZpgkAtF7PbH9s7wbiTRNcM0SPByzFHw=";
            openSha256 = "sha256-Fxo0t61KQDs71YA8u7arY+503wkAc1foaa51vi2Pl5I=";
            settingsSha256 = "sha256-VUetj3LlOSz/LB+DDfMCN34uA4bNTTpjDrb6C6Iwukk=";
            persistencedSha256 = "";

            patches = [
              (patch /nvidia/6.13/0001-KBuild-changes.patch)
              (patch /nvidia/6.13/0002-FROM-AOSC-Use-linux-aperture.c-for-removing-conflict.patch)
              (patch /nvidia/6.13/0003-FROM-AOSC-TTM-fbdev-emulation-for-Linux-6.13.patch)
            ];
          }).overrideAttrs (finalAttrs': prevAttrs': {
            # patched builder.sh to not include some egl libraries to prevent apps from blocking nvidia_drm unloading
            builder = (patch /nvidia/builder.sh);

            makeFlags = [
              "IGNORE_PREEMPT_RT_PRESENCE=1"
              "NV_BUILD_SUPPORTS_HMM=1"
              "SYSSRC=${finalAttrs.kernel.dev}/lib/modules/${finalAttrs.kernel.modDirVersion}/source"
              "SYSOUT=${finalAttrs.kernel.dev}/lib/modules/${finalAttrs.kernel.modDirVersion}/build"
            ];

            passthru = prevAttrs'.passthru // {
              open = prevAttrs'.passthru.open.overrideAttrs (finalAttrs'': prevAttrs'': {
                patches = prevAttrs''.patches ++ [
                  (patch /nvidia/6.13/0004-OPEN-Fix-MODULE_IMPORT_NS.patch)
                  (patch /nvidia/6.13/0005-OPEN-disable-LKCA.patch)
                ];

                makeFlags = [
                  "SYSSRC=${finalAttrs.kernel.dev}/lib/modules/${finalAttrs.kernel.modDirVersion}/source"
                  "SYSOUT=${finalAttrs.kernel.dev}/lib/modules/${finalAttrs.kernel.modDirVersion}/build"
                  "MODLIB=$(out)/lib/modules/${finalAttrs.kernel.modDirVersion}"
                  {
                    aarch64-linux = "TARGET_ARCH=aarch64";
                    x86_64-linux = "TARGET_ARCH=x86_64";
                  }.${finalAttrs.stdenv.hostPlatform.system}
                ];
              });

              #settings = prevAttrs'.passthru.settings.overrideAttrs (prevAttrs'': {});
            };
          });
        })).nvidiaPackages.production;
    modesetting.enable = true;
    #nvidiaPersistenced = true;
    open = true; # open kernel driver keeps dying frequently currently (failed to allocate vmap() page descriptor table!)
    prime = {
      offload.enable = true;
      nvidiaBusId = "PCI:1:0:0";
    } // lib.optionalAttrs (platform == "intel") { intelBusId = "PCI:0:2:0"; }
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

