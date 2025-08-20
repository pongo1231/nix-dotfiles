{
  config,
  pkgs,
  ...
}:
{
  boot = {
    kernelModules = [ "ryzen_smu" ];

    kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "amd_pstate=active"
    ];

    extraModulePackages = with config.boot.kernelPackages; [
      (ryzen-smu.overrideAttrs {
        src = pkgs.fetchFromGitHub {
          owner = "amkillam";
          repo = "ryzen_smu";
          rev = "9f9569f889935f7c7294cc32c1467e5a4081701a";
          hash = "sha256-i8T0+kUYsFMzYO3h6ffUXP1fgGOXymC4Ml2dArQLOdk=";
        };
      })
    ];
  };

  environment.systemPackages = with pkgs; [
    ryzenadj
  ];
}
