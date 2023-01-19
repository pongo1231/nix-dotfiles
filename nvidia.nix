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
              version = "525.85.05";
              sha256_64bit = "sha256-6mO0JTQDsiS7cxOol3qSDf6dID1mHdX2/CZYWnAXkUA=";
              openSha256 = lib.fakeSha256;
              settingsSha256 = "sha256-ck6ra8y8nn5kA3L9/VcRR2W2RaWvfVbgBiOh2dRJr/8=";
              persistencedSha256 = "sha256-dt/Tqxp7ZfnbLel9BavjWDoEdLJvdJRwFjTFOBYYKLI=";
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
