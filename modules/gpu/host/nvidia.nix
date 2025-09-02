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
              version = "580.82.07";
              sha256_64bit = "sha256-Bh5I4R/lUiMglYEdCxzqm3GLolQNYFB0/yJ/zgYoeYw=";
              openSha256 = "sha256-8/7ZrcwBMgrBtxebYtCcH5A51u3lAxXTCY00LElZz08=";
              settingsSha256 = "sha256-lx1WZHsW7eKFXvi03dAML6BoC5glEn63Tuiz3T867nY=";
              persistencedSha256 = "";
              patches = [
                #(patch /nvidia/6.17/917.patch)
              ];
            }).overrideAttrs
              (prev': {
                # patched builder.sh to not include some egl libraries to prevent apps from blocking nvidia_drm unloading
                #builder = patch /nvidia/builder.sh;

                makeFlags = prev'.makeFlags ++ final.kernel.extraMakeFlags;

                passthru = prev'.passthru // {
                  open = prev'.passthru.open.overrideAttrs (prev'': {
                    makeFlags =
                      prev''.makeFlags
                      ++ final.kernel.extraMakeFlags
                      ++ [
                        "CC=${pkgs.llvmPackages_21.stdenv.cc}/bin/clang"
                      ];

                    NIX_CFLAGS_COMPILE = "-O3 -flto=thin -march=x86-64-v3 -Wno-error=unused-command-line-argument";
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
    // lib.optionalAttrs (platform == "intel") { intelBusId = "PCI:0:2:0"; }
    // lib.optionalAttrs (platform == "amd") { amdgpuBusId = "PCI:5:0:0"; };
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    dynamicBoost.enable = true;
  };

  boot.extraModprobeConfig = ''
    options nvidia NVreg_UsePageAttributeTable=1 NVreg_InitializeSystemMemoryAllocations=0 NVreg_EnablePCIeGen3=1 NVreg_RegistryDwords=RMIntrLockingMode=1
    options nvidia_drm fbdev=0
  '';
}
