{ pkgs
, config
, lib
, inputs
, ...
}:
let
  prime-run = pkgs.writeShellScriptBin "prime-run" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    # export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec -a "$0" "$@"
  '';
in
{
  nixpkgs.overlays = [
    (self: super: {
      linuxPackages_custom = self.linuxPackages_6_1.extend
        (selfLinux: superLinux:
          let generic = args: selfLinux.callPackage (import (inputs.nixpkgs + "/pkgs/os-specific/linux/nvidia-x11/generic.nix") args) { };
          in {
            nvidiaPackages.production = generic {
              version = "530.41.03";
              sha256_64bit = "sha256-riehapaMhVA/XRYd2jQ8FgJhKwJfSu4V+S4uoKy3hLE=";
              openSha256 = lib.fakeSha256;
              settingsSha256 = "sha256-8KB6T9f+gWl8Ni+uOyrJKiiH5mNx9eyfCcW/RjPTQQA=";
              persistencedSha256 = "sha256-zrstlt/0YVGnsPGUuBbR9ULutywi2wNDVxh7OhJM7tM=";
            };
          });
    })
  ];

  environment.systemPackages = [ prime-run ];  

  hardware.nvidia.package = pkgs.linuxPackages_custom.nvidiaPackages.production;

  services.xserver = {
    videoDrivers = [ "nvidia" ];
    deviceSection = ''
      Option "Coolbits" "8"
    '';
    serverLayoutSection = ''
      Inactive "Device-nvidia[0]"
    '';
    exportConfiguration = true;
  };

  hardware.nvidia = {
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
}
