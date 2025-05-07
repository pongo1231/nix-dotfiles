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
        finalAttrs: _:
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
              version = "570.133.07";
              sha256_64bit = "sha256-LUPmTFgb5e9VTemIixqpADfvbUX1QoTT2dztwI3E3CY=";
              openSha256 = "sha256-9l8N83Spj0MccA8+8R1uqiXBS0Ag4JrLPjrU3TaXHnM=";
              settingsSha256 = "sha256-XMk+FvTlGpMquM8aE8kgYK2PIEszUZD2+Zmj2OpYrzU=";
              persistencedSha256 = "";
              patches = [ (patch /nvidia/6.15/build-fix.patch) ];
            }).overrideAttrs
              (prevAttrs': {
                # patched builder.sh to not include some egl libraries to prevent apps from blocking nvidia_drm unloading
                builder = patch /nvidia/builder.sh;

                patches = prevAttrs'.patches ++ [ (patch /nvidia/6.15/gpl-hack.patch) ];

                /*
                  passthru = prevAttrs'.passthru // {
                    open = prevAttrs'.passthru.open.overrideAttrs (
                      finalAttrs'': prevAttrs'': {
                        patches = prevAttrs''.patches ++ [ ];
                      }
                    );
                  };
                */
              });
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

  boot.extraModprobeConfig = ''
    options nvidia NVreg_UsePageAttributeTable=1 NVreg_InitializeSystemMemoryAllocations=0 NVreg_DynamicPowerManagement=0x02 NVreg_RegistryDwords=RMIntrLockingMode=1
    options nvidia_drm modeset=1
  '';

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "prime-run" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec -a "$0" "$@"
    '')
  ];
}
