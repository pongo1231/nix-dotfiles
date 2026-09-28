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
      (ryzen-smu.overrideAttrs (
        prev:
        let
          version = "0.1.7-unstable-2026-08-15";

          src = pkgs.fetchFromGitHub {
            owner = "amkillam";
            repo = "ryzen_smu";
            rev = "d2983668300dd2a598e5a7dc40e71ce0678cc270";
            hash = "sha256-OmEoycRO3hGkqueLa0i6AzmwMEbdkkPrwJkMyYxOTek=";
          };

          monitor-cpu = kernel.stdenv.mkDerivation {
            pname = "monitor-cpu";

            inherit version src;

            makeFlags = kernel.extraMakeFlags ++ [
              "CC=${pkgs.llvmPackages_latest.stdenv.cc}/bin/clang"
              "-C userspace"
            ];

            installPhase = ''
              runHook preInstall
              install userspace/monitor_cpu -Dm755 -t $out/bin
              runHook postInstall
            '';
          };
        in
        {
          inherit version src;

          makeFlags = (prev.makeFlags or [ ]) ++ kernel.extraMakeFlags;

          installPhase = ''
            runHook preInstall
            install ryzen_smu.ko -Dm444 -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/ryzen_smu
            install ${monitor-cpu}/bin/monitor_cpu -Dm755 -t $out/bin
            runHook postInstall
          '';
        }
      ))
    ];
  };

  environment.systemPackages = with pkgs; [
    ryzenadj
  ];
}
