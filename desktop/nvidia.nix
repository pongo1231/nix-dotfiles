{ platform }:
{ config
, pkgs
, lib
, inputs
, ...
}:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  /*boot.extraModprobeConfig = ''
    options nvidia NVreg_EnableGpuFirmware=0
  '';*/

  hardware.nvidia = {
    package = (config.boot.kernelPackages.extend
      (finalAttrs: prevAttrs:
        let generic = args: finalAttrs.callPackage (import "${inputs.nixpkgs}/pkgs/os-specific/linux/nvidia-x11/generic.nix" args) { };
        in {
          nvidiaPackages.production = (generic {
            version = "555.58.02";
            sha256_64bit = "sha256-xctt4TPRlOJ6r5S54h5W6PT6/3Zy2R4ASNFPu8TSHKM=";
            openSha256 = "sha256-8hyRiGB+m2hL3c9MDA/Pon+Xl6E788MZ50WrrAGUVuY=";
            settingsSha256 = "sha256-ZpuVZybW6CFN/gz9rx+UJvQ715FZnAOYfHn5jt5Z2C8=";
            persistencedSha256 = "";
            #patches = [ ../patches/nvidia/6.10.patch ];
          }).overrideAttrs (prevAttrs': {
            builder = ../patches/nvidia/builder.sh;
            /*passthru = prevAttrs'.passthru // {
              open = prevAttrs'.passthru.open.overrideAttrs (prevAttrs'': {
                patches = (prevAttrs''.patches or [ ]) ++ [ ../patches/nvidia/6.10-open.patch ];
              });
            };*/
          });
        })).nvidiaPackages.production;
    modesetting.enable = true;
    #nvidiaPersistenced = true;
    open = true;
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
