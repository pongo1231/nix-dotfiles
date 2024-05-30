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
      (finalAttrs: prevAttrs:
        let generic = args: finalAttrs.callPackage (import "${inputs.nixpkgs}/pkgs/os-specific/linux/nvidia-x11/generic.nix" args) { };
        in {
          nvidiaPackages.production = (generic {
            version = "555.42.02";
            sha256_64bit = "sha256-k7cI3ZDlKp4mT46jMkLaIrc2YUx1lh1wj/J4SVSHWyk=";
            openSha256 = "sha256-3/eI1VsBzuZ3Y6RZmt3Q5HrzI2saPTqUNs6zPh5zy6w=";
            settingsSha256 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
            persistencedSha256 = "sha256-3ae31/egyMKpqtGEqgtikWcwMwfcqMv2K4MVFa70Bqs=";
            patches = [ ../patches/nvidia/6.10.patch ];
          }).overrideAttrs (prevAttrs': {
            #builder = ../patches/nvidia/builder.sh;
            passthru = prevAttrs'.passthru // {
              open = prevAttrs'.passthru.open.overrideAttrs (prevAttrs'': {
                patches = (prevAttrs''.patches or [ ]) ++ [ ../patches/nvidia/6.10-open.patch ];
              });
            };
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
