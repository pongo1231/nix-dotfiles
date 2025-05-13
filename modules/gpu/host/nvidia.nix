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
          nvidiaPackagesbeta =
            (generic {
              version = "575.51.02";
              #sha256_64bit = "sha256-XZ0N8ISmoAC8p28DrGHk/YN1rJsInJ2dZNL8O+Tuaa0=";
              openSha256 = "sha256-bkvp/rypEqZUR15wGsKt0VxIvbdaMcGLP12QqtA2bFE=";
              settingsSha256 = "sha256-6n9mVkEL39wJj5FB1HBml7TTJhNAhS/j5hqpNGFQE4w=";
              persistencedSha256 = "";
              patches = [ (patch /nvidia/6.15/Kbuild-Convert-EXTRA_CFLAGS-to-ccflags-y.patch) (patch /nvidia/6.15/kbuild-Add-workaround-for-GCC-15-Compilation.patch) ];
            }).overrideAttrs
              (prevAttrs': {
                # patched builder.sh to not include some egl libraries to prevent apps from blocking nvidia_drm unloading
                #builder = patch /nvidia/builder.sh;

                #patches = prevAttrs'.patches ++ [ (patch /nvidia/6.15/gpl-hack.patch) ];

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
      )).nvidiaPackages.beta;

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
