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
        final: prev:
        let
          version = "0.1.7-git";

          src = pkgs.fetchFromGitHub {
            owner = "amkillam";
            repo = "ryzen_smu";
            rev = "9f9569f889935f7c7294cc32c1467e5a4081701a";
            hash = "sha256-i8T0+kUYsFMzYO3h6ffUXP1fgGOXymC4Ml2dArQLOdk=";
          };

          monitor-cpu = kernel.stdenv.mkDerivation {
            pname = "monitor-cpu";

            inherit version src;

            makeFlags = [
              "LLVM=1"
              "CC=${final.stdenv.cc}/bin/clang"
              "-C userspace"
            ];

            hardeningDisable = [ "strictoverflow" ];

            installPhase = ''
              runHook preInstall
              install userspace/monitor_cpu -Dm755 -t $out/bin
              runHook postInstall
            '';
          };
        in
        {
          inherit version src;

          inherit (kernel) stdenv;

          makeFlags = (prev.makeFlags or [ ]) ++ [
            "LLVM=1"
            "CC=${final.stdenv.cc}/bin/clang"
          ];

          hardeningDisable = [ "strictoverflow" ];

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
