{ pkgs
, config
, inputs
, ...
}:
{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    package = (config.boot.kernelPackages.extend
      (selfLinux: superLinux:
        let generic = args: selfLinux.callPackage (import "${inputs.nixpkgs}/pkgs/os-specific/linux/nvidia-x11/generic.nix" args) { };
        in {
          nvidiaPackages.production = (generic {
            version = "550.67";
            sha256_64bit = "sha256-mSAaCccc/w/QJh6w8Mva0oLrqB+cOSO1YMz1Se/32uI=";
            settingsSha256 = "sha256-FUEwXpeUMH1DYH77/t76wF1UslkcW721x9BHasaRUaM=";
            persistencedSha256 = "sha256-mmBB2pfwzI1WYOffMVdD0N1HfbswTGg7o57x9/IiyVU=";
          }).overrideAttrs (prevAttrs: {
            builder = ../patches/nvidia/builder.sh;
          });
        })).nvidiaPackages.production;
    modesetting.enable = true;
    prime = {
      offload.enable = true;
      nvidiaBusId = "PCI:1:0:0";
      intelBusId = "PCI:0:2:0";
    };
    powerManagement = {
      enable = true;
      finegrained = true;
    };
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