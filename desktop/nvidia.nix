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
            version = "560.28.03";
            sha256_64bit = "sha256-martv18vngYBJw1IFUCAaYr+uc65KtlHAMdLMdtQJ+Y=";
            openSha256 = "sha256-asGpqOpU0tIO9QqceA8XRn5L27OiBFuI9RZ1NjSVwaM=";
            settingsSha256 = "sha256-b4nhUMCzZc3VANnNb0rmcEH6H7SK2D5eZIplgPV59c8=";
            persistencedSha256 = "";
            #patches = [ ../patches/nvidia/6.10.patch ];
          }).overrideAttrs (prevAttrs': {
            # patched builder.sh to not include some egl libraries to prevent apps from blocking nvidia_drm unloading
            builder = ../patches/nvidia/builder.sh;
            passthru = prevAttrs'.passthru // {
              /*open = prevAttrs'.passthru.open.overrideAttrs (prevAttrs'': {
                nativeBuildInputs = prevAttrs''.nativeBuildInputs ++ [ pkgs.vulkan-headers ];
                #patches = (prevAttrs''.patches or [ ]) ++ [ ../patches/nvidia/6.10-open.patch ];
              });*/
              settings = prevAttrs'.passthru.settings.overrideAttrs (prevAttrs'': {
                nativeBuildInputs = prevAttrs''.nativeBuildInputs ++ [ pkgs.vulkan-headers ];
              });
            };
          });
        })).nvidiaPackages.production;
    modesetting.enable = true;
    #nvidiaPersistenced = true;
    open = true; # open kernel driver keeps dying frequently currently (failed to allocate vmap() page descriptor table!)
    prime = {
      offload.enable = true;
      nvidiaBusId = "PCI:1:0:0";
    } // lib.optionalAttrs (platform == "intel") {
      intelBusId = "PCI:0:2:0";
    } // lib.optionalAttrs (platform == "amd") {
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
