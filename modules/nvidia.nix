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
        finalAttrs: prevAttrs:
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
              version = "570.124.04";
              sha256_64bit = "sha256-G3hqS3Ei18QhbFiuQAdoik93jBlsFI2RkWOBXuENU8Q=";
              openSha256 = "sha256-KCGUyu/XtmgcBqJ8NLw/iXlaqB9/exg51KFx0Ta5ip0=";
              settingsSha256 = "sha256-LNL0J/sYHD8vagkV1w8tb52gMtzj/F0QmJTV1cMaso8=";
              persistencedSha256 = "";
            }).overrideAttrs
              (
                finalAttrs': prevAttrs': {
                  # patched builder.sh to not include some egl libraries to prevent apps from blocking nvidia_drm unloading
                  builder = (patch /nvidia/builder.sh);

                  passthru = prevAttrs'.passthru // {
                    open = prevAttrs'.passthru.open.overrideAttrs (
                      finalAttrs'': prevAttrs'': {
                        patches = prevAttrs''.patches ++ [ ];
                      }
                    );
                  };
                }
              );
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

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "prime-run" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec -a "$0" "$@"
    '')
  ];
}
