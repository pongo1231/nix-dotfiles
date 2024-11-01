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
            version = "565.57.01";
            sha256_64bit = "sha256-buvpTlheOF6IBPWnQVLfQUiHv4GcwhvZW3Ks0PsYLHo=";
            openSha256 = "sha256-/tM3n9huz1MTE6KKtTCBglBMBGGL/GOHi5ZSUag4zXA=";
            settingsSha256 = "sha256-H7uEe34LdmUFcMcS6bz7sbpYhg9zPCb/5AmZZFTx1QA=";
            persistencedSha256 = "";
            #patches = [ (patch /nvidia/0006-Fix-for-6.12.0-rc1-drm_mode_config_funcs.output_poll.patch) ];
          }).overrideAttrs (prevAttrs': {
            # patched builder.sh to not include some egl libraries to prevent apps from blocking nvidia_drm unloading
            builder = (patch /nvidia/builder.sh);

            patches = prevAttrs'.patches ++ [

            ];

            passthru = prevAttrs'.passthru // {
              open = prevAttrs'.passthru.open.overrideAttrs (prevAttrs'': {
                patches = prevAttrs''.patches ++ [
                  #(patch /nvidia/open/0006-Fix-for-6.12.0-rc1-drm_mode_config_funcs.output_poll.patch)
                  #(patch /nvidia/open/0007-Replace-PageSwapCache-for-6.12-kernel.patch)
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

