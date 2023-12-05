{ pkgs
, config
, inputs
, ...
}:
{
  nixpkgs.config.nvidia.acceptLicense = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    package = (config.boot.kernelPackages.extend
      (selfLinux: superLinux:
        let generic = args: selfLinux.callPackage (import "${inputs.nixpkgs}/pkgs/os-specific/linux/nvidia-x11/generic.nix" args) { };
        in {
          nvidiaPackages.production = (generic {
            version = "545.29.02";
            sha256_64bit = "sha256-RncPlaSjhvBFUCOzWdXSE3PAfRPCIrWAXyJMdLPKuIU=";
            settingsSha256 = "sha256-zj173HCZJaxAbVV/A2sbJ9IPdT1+3yrwyxD+AQdkSD8=";
            persistencedSha256 = "sha256-mmMi2pfwzI1WYOffMVdD0N1HfbswTGg7o57x9/IiyVU=";
          }).overrideAttrs (oldAttrs: {
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
    nvidiaPersistenced = true;
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
