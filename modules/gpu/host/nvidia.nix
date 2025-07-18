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
        final: _:
        let
          generic =
            args:
            final.callPackage (import "${inputs.nixpkgs}/pkgs/os-specific/linux/nvidia-x11/generic.nix" args)
              { };
        in
        {
          nvidiaPackages.beta =
            (generic {
              version = "575.64.03";
              sha256_64bit = "sha256-S7eqhgBLLtKZx9QwoGIsXJAyfOOspPbppTHUxB06DKA=";
              openSha256 = "sha256-SAl1+XH4ghz8iix95hcuJ/EVqt6ylyzFAao0mLeMmMI=";
              settingsSha256 = "sha256-o8rPAi/tohvHXcBV+ZwiApEQoq+ZLhCMyHzMxIADauI=";
              persistencedSha256 = "";
              patches = [
                #(patch /nvidia/6.15/Kbuild-Convert-EXTRA_CFLAGS-to-ccflags-y.patch)
                #(patch /nvidia/6.15/kernel-open-nvidia-Use-new-timer-functions-for-6.15.patch)
                #(patch /nvidia/6.15/Workaround-nv_vm_flags_-calling-GPL-only-code.patch)
                #(patch /nvidia/6.15/nvidia-uvm-Use-__iowrite64_hi_lo.patch)
              ];
            }).overrideAttrs
              (prev': {
                # patched builder.sh to not include some egl libraries to prevent apps from blocking nvidia_drm unloading
                #builder = patch /nvidia/builder.sh;

                passthru = prev'.passthru // {
                  open = prev'.passthru.open.overrideAttrs (prev'': {
                    patches = prev''.patches ++ [
                      #(patch /nvidia/6.15/nvidia-uvm-Use-page_pgmap.patch)
                      #(patch /nvidia/6.15/nvidia-uvm-Convert-make_device_exclusive_range-to-ma.patch)
                      #(patch /nvidia/6.16/dma_buf_attachment_is_dynamic.patch)
                      #(patch /nvidia/6.16/no_dev_disable_enable_feature.patch)
                    ];
                  });
                };
              });
        }
      )).nvidiaPackages.beta;

    modesetting.enable = true;
    open = true;
    prime =
      {
        offload = {
          enable = true;
          enableOffloadCmd = true;
          offloadCmdMainProgram = "prime-run";
        };
        reverseSync.enable = true;
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
}
