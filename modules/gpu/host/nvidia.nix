{
  gpus,
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
        final: prev:
        let
          generic =
            args:
            final.callPackage (import "${inputs.nixpkgs}/pkgs/os-specific/linux/nvidia-x11/generic.nix" args)
              { };
        in
        {
          nvidiaPackages.beta =
            (generic {
              version = "580.105.08";
              sha256_64bit = "sha256-2cboGIZy8+t03QTPpp3VhHn6HQFiyMKMjRdiV2MpNHU=";
              openSha256 = "sha256-FGmMt3ShQrw4q6wsk8DSvm96ie5yELoDFYinSlGZcwQ=";
              settingsSha256 = "sha256-YvzWO1U3am4Nt5cQ+b5IJ23yeWx5ud1HCu1U0KoojLY=";
              persistencedSha256 = "";
              patches = [
                (patch /nvidia/6.19/fix-build.patch)
              ];
              patchesOpen = [
                (patch /nvidia/6.18/fix-6.18-build.patch)
              ];
            }).overrideAttrs
              (prev': {
                # patched builder.sh to not include some egl libraries to prevent apps from blocking nvidia_drm unloading
                #builder = patch /nvidia/builder.sh;

                makeFlags = prev'.makeFlags ++ final.kernel.extraMakeFlags;

                passthru = prev'.passthru // {
                  open = prev'.passthru.open.overrideAttrs (prev'': {
                    makeFlags = prev''.makeFlags ++ final.kernel.extraMakeFlags;

                    #NIX_CFLAGS_COMPILE = "-Wno-error=unused-command-line-argument";
                  });
                };
              });
        }
      )).nvidiaPackages.beta;

    modesetting.enable = true;
    open = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
        offloadCmdMainProgram = "prime-run";
      };
      reverseSync.enable = true;
      nvidiaBusId = "PCI:1:0:0";
    }
    // lib.optionalAttrs (builtins.elem "intel" gpus) { intelBusId = "PCI:0:2:0"; }
    // lib.optionalAttrs (builtins.elem "amd" gpus) { amdgpuBusId = "PCI:5:0:0"; };
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    dynamicBoost.enable = true;
  };

  boot = {
    kernelParams = [ "modprobe.blacklist=nouveau" ];

    extraModprobeConfig = ''
      options nvidia NVreg_UsePageAttributeTable=1 NVreg_InitializeSystemMemoryAllocations=0 NVreg_EnablePCIeGen3=1 NVreg_RegistryDwords=RMIntrLockingMode=1
    '';
  };
}
