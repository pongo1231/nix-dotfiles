{ config
, pkgs
, lib
, inputs
, ...
}:
{
  imports = [
    inputs.kde2nix.nixosModules.default
  ];

  nix.daemonCPUSchedPolicy = "idle";

  boot = {
    kernelPackages = lib.lowPrio (pkgs.kernel.zfs.override { removeLinuxDRM = pkgs.hostPlatform.isAarch64; }).latestCompatibleLinuxPackages;
    extraModulePackages = with config.boot.kernelPackages; lib.mkDefault [ xpadneo ];
    plymouth.enable = lib.mkDefault true;

    supportedFilesystems = [ "zfs" ];
    extraModprobeConfig = ''
      options zfs zfs_bclone_enabled=1 spl_taskq_thread_priority=0
    '';

    zfs = {
      package = pkgs.kernel.zfs;
      removeLinuxDRM = true;
    };
  };

  services = {
    xserver = {
      displayManager.sddm = {
        enable = lib.mkDefault true;
        wayland.enable = true;
        autoNumlock = true;
      };
      desktopManager.plasma6.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    sddm-kcm
  ];
}
