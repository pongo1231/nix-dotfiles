{ pkgs
, config
, lib
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
      linuxPackages = super.linuxPackages.extend
        (selfLinux: superLinux: {
          nvidia_x11 =
            superLinux.nvidia_x11.overrideAttrs (finalAttrs: previousAttrs: {
              useGLVND = false; # stop KDE wayland session from waking up dgpu
              builder = ./nvidia/builder.sh;
            });
        });
    })
  ];

  environment.systemPackages = with pkgs; [ prime-run nvoc ];

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
      reverse_sync.enable = false;
      nvidiaBusId = "PCI:1:0:0";
      intelBusId = "PCI:0:2:0";
      allowExternalGpu = true;
      sync.enable = false;
    };
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    nvidiaPersistenced = true;
  };

  /*
            environment.etc."X11/xorg.conf.d/10-prime.conf".text = ''
            Section "OutputClass"
      Identifier "nvidia"
      MatchDriver "nvidia-drm"
      Driver "nvidia"
      Option "AllowEmptyInitialConfiguration"
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
                                                                                    	Option     "Coolbits" "24"
      Option     "Interactive" "0"
            EndSection

            Section "Screen"
                                                                                    	Identifier "dGPU"
                                                                                    	Device     "dGPU"
                                                                                    	Option     "AllowEmptyInitialConfiguration"
            EndSection
            '';
            */
}
