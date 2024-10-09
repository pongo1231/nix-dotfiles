{ platform }:
{ config
, pkgs
, lib
, inputs
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
            version = "560.35.03";
            sha256_64bit = "sha256-8pMskvrdQ8WyNBvkU/xPc/CtcYXCa7ekP73oGuKfH+M=";
            openSha256 = "sha256-/32Zf0dKrofTmPZ3Ratw4vDM7B+OgpC4p7s+RHUjCrg=";
            settingsSha256 = "sha256-kQsvDgnxis9ANFmwIwB7HX5MkIAcpEEAHc8IBOLdXvk=";
            persistencedSha256 = "";
            patches = [ ../patches/nvidia/0006-Fix-for-6.12.0-rc1-drm_mode_config_funcs.output_poll.patch ];
          }).overrideAttrs (prevAttrs': {
            # patched builder.sh to not include some egl libraries to prevent apps from blocking nvidia_drm unloading
            builder = ../patches/nvidia/builder.sh;

            patches = prevAttrs'.patches ++ [

            ];

            passthru = prevAttrs'.passthru // {
              open = prevAttrs'.passthru.open.overrideAttrs (prevAttrs'': {
                patches = prevAttrs''.patches ++ [
                  ../patches/nvidia/open/0006-Fix-for-6.12.0-rc1-drm_mode_config_funcs.output_poll.patch
                  ../patches/nvidia/open/0007-Replace-PageSwapCache-for-6.12-kernel.patch
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
    } // lib.optionalAttrs
      (platform == "intel")
      {
        intelBusId = "PCI:0:2:0";
      } // lib.optionalAttrs
      (platform == "amd")
      {
        amdgpuBusId = "PCI:5:0:0";
      };
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

