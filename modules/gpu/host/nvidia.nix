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
              version = "580.82.09";
              sha256_64bit = "sha256-Puz4MtouFeDgmsNMKdLHoDgDGC+QRXh6NVysvltWlbc=";
              openSha256 = "sha256-YB+mQD+oEDIIDa+e8KX1/qOlQvZMNKFrI5z3CoVKUjs=";
              settingsSha256 = "sha256-um53cr2Xo90VhZM1bM2CH4q9b/1W2YOqUcvXPV6uw2s=";
              persistencedSha256 = "";
              patches = [

              ];
            }).overrideAttrs
              (prev': {
                # patched builder.sh to not include some egl libraries to prevent apps from blocking nvidia_drm unloading
                #builder = patch /nvidia/builder.sh;

                makeFlags = prev'.makeFlags ++ final.kernel.extraMakeFlags;

                passthru = prev'.passthru // {
                  open = prev'.passthru.open.overrideAttrs (prev'': {
                    /*
                      patches = [
                        (pkgs.fetchpatch {
                          url = "https://gist.githubusercontent.com/sharkautarch/4e63bbdcb27aafb0bc755f35cf77e69a/raw/d2f7a22c21b9dce2c6da0710ffc8868c13c002df/0002-workaround-kcfi-issues.patch";
                          hash = "sha256-PoMcu6KZcjx1F9ciaBM5VJNPD8bLsihFVruAtjXJgWI=";
                        })
                      ];
                    */

                    makeFlags =
                      prev''.makeFlags
                      ++ final.kernel.extraMakeFlags
                      ++ [
                        #"CC=${pkgs.llvmPackages_21.stdenv.cc}/bin/clang"
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
  '';
}
