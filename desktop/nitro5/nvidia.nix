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
            version = "550.54.14";
            sha256_64bit = "sha256-jEl/8c/HwxD7h1FJvDD6pP0m0iN7LLps0uiweAFXz+M=";
            settingsSha256 = "sha256-m2rNASJp0i0Ez2OuqL+JpgEF0Yd8sYVCyrOoo/ln2a4=";
            persistencedSha256 = "sha256-mmMB2pfwzI1WYOffMVdD0N1HfbswTGg7o57x9/IiyVU=";
          }).overrideAttrs (prevAttrs: {
            builder = ../../patches/nvidia/builder.sh;
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
