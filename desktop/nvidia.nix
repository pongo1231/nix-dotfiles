{ platform }:
{ config
, pkgs
, lib
, inputs
, ...
}:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    package = (config.boot.kernelPackages.extend
      (final: prev:
        let generic = args: final.callPackage (import "${inputs.nixpkgs}/pkgs/os-specific/linux/nvidia-x11/generic.nix" args) { };
        in {
          nvidiaPackages.production = prev.nvidiaPackages.production.overrideAttrs (prevAttrs: {
            builder = ../patches/nvidia/builder.sh;
          });
        })).nvidiaPackages.production;
    modesetting.enable = true;
    nvidiaPersistenced = true;
    #open = true;
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
