{ platform }:
{ config
, pkgs
, lib
, inputs
, ...
}:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  boot.extraModprobeConfig = ''
    options nvidia NVreg_EnableGpuFirmware=0
  '';

  hardware.nvidia = {
    package = (config.boot.kernelPackages.extend
      (finalAttrs: prevAttrs:
        let generic = args: finalAttrs.callPackage (import "${inputs.nixpkgs}/pkgs/os-specific/linux/nvidia-x11/generic.nix" args) { };
        in {
          nvidiaPackages.production = (generic {
            version = "555.52.04";
            sha256_64bit = "sha256-nVOubb7zKulXhux9AruUTVBQwccFFuYGWrU1ZiakRAI=";
            openSha256 = "sha256-wDimW8/rJlmwr1zQz8+b1uvxxxbOf3Bpk060lfLKuy0=";
            settingsSha256 = "sha256-PMh5efbSEq7iqEMBr2+VGQYkBG73TGUh6FuDHZhmwHk=";
            persistencedSha256 = "sha256-KAYIvPjUVilQQcD04h163MHmKcQrn2a8oaXujL2Bxro=";
            #patches = [ ../patches/nvidia/6.10.patch ];
          }).overrideAttrs (prevAttrs': {
            /*builder = ../patches/nvidia/builder.sh;
            passthru = prevAttrs'.passthru // {
              open = prevAttrs'.passthru.open.overrideAttrs (prevAttrs'': {
                patches = (prevAttrs''.patches or [ ]) ++ [ ../patches/nvidia/6.10-open.patch ];
              });
            };*/
          });
        })).nvidiaPackages.production;
    modesetting.enable = true;
    nvidiaPersistenced = true;
    open = false;
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
