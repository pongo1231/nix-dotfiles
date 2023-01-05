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
      linuxPackages = config.boot.kernelPackages.extend
        (selfLinux: superLinux:
          let generic = args: selfLinux.callPackage (import (inputs.nixpkgs-unstable + "/pkgs/os-specific/linux/nvidia-x11/generic.nix") args) { };
          in {
            nvidiaPackages.production = generic {
              version = "525.78.01";
              sha256_64bit = "sha256-Q9pC0r9pvDfqnHwPoC9S2w3MSDwnL1LtrK2JpctJWpM=";
              openSha256 = "sha256-33ATZuYu+SOOxM6UKXp6B+f1+zbmHvaK4v13X3UZTTM=";
              settingsSha256 = "sha256-1d3Cn+7Gm1ORQxmTKr18GFmYHVb8t050XVLler1dCtw=";
              persistencedSha256 = "sha256-t6dViuvA2fw28w4kh4koIoxh9pQ8f7KI1PIUFJcGlYA=";
            };
          });
    })
  ];

  environment.systemPackages = [ prime-run ];

  hardware.nvidia.package = pkgs.linuxPackages.nvidiaPackages.production;

  services.xserver = {
    /*
      videoDrivers = ["intel" "nvidia"];

      config = lib.mkForce ''
      Section "OutputClass"
        Identifier "nvidia"
        MatchDriver "nvidia-drm"
        Driver "nvidia"
        Option "AllowEmptyInitialConfiguration"
        Option     "Coolbits" "8"
        ModulePath "/run/current-system/sw/lib/xorg/modules/extensions"
        ModulePath "/run/current-system/sw/lib/xorg/modules"
      EndSection

      Section "Device"
      Identifier "iGPU"
      Driver     "intel"
      BusID      "PCI:0:2:0"
      EndSection

      Section "Screen"
      Identifier "iGPU"
      Device     "iGPU"
      EndSection

      Section "Device"
      Identifier "dGPU"
      Driver     "nvidia"
      BusID      "PCI:1:0:0"
      Option     "Coolbits" "8"
      EndSection

      Section "Screen"
      Identifier "dGPU"
      Device     "dGPU"
      Option     "AllowEmptyInitialConfiguration"
      EndSection
      '';
    */

    videoDrivers = [ "nvidia" ];
    deviceSection = ''
      Option "Coolbits" "8"
    '';
    #displayManager = {
    /*
      sessionCommands = ''
      # ${pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 1 0
      # ${pkgs.xorg.xrandr}/bin/xrandr --auto
      '';
    */
    #};
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
      sync.enable = false;
    };
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    nvidiaPersistenced = true;
  };
}
