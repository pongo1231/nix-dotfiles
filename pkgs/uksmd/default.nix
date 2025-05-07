{
  pkgs,
  ...
}:
let
  uksmd = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "uksmd";
    version = "1.2.12";

    src = pkgs.fetchFromGitHub {
      owner = "CachyOS";
      repo = finalAttrs.pname;
      rev = "v${finalAttrs.version}";
      sha256 = "sha256-7w9/3x5DCWPlM+6LrWszuCvHZSk/z0qdr2h8MPBPHvc=";
    };

    nativeBuildInputs = [
      pkgs.pkg-config
      pkgs.meson
      pkgs.cmake
      pkgs.ninja
    ];

    buildInputs = [
      pkgs.procps
      pkgs.libcap_ng
      pkgs.systemd
    ];

    mesonFlags = [ "-Dlibalpm=disabled" ];

    installPhase = ''
      mkdir -p $out/bin/
      mv uksmd $out/bin/
    '';
  });
in
{
  systemd.services.uksmd = {
    enable = true;
    wantedBy = [ "multi-user.target" ];

    unitConfig = {
      Description = "Userspace KSM helper daemon";
      Documentation = "https://codeberg.org/pf-kernel/uksmd";
      ConditionPathExists = [
        "/sys/kernel/process_ksm/process_ksm_enable"
        "/sys/kernel/process_ksm/process_ksm_disable"
        "/sys/kernel/process_ksm/process_ksm_status"
      ];
    };

    serviceConfig = {
      Type = "notify";
      DynamicUser = true;
      User = "uksmd";
      Group = "uksmd";
      CapabilityBoundingSet = [
        "CAP_SYS_PTRACE"
        "CAP_DAC_OVERRIDE"
        "CAP_SYS_NICE"
      ];
      AmbientCapabilities = [
        "CAP_SYS_PTRACE"
        "CAP_DAC_OVERRIDE"
        "CAP_SYS_NICE"
      ];
      PrivateNetwork = "yes";
      RestrictAddressFamilies = "AF_UNIX";
      RestrictNamespaces = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ReadWritePaths = "/sys/kernel/mm/ksm/run";
      ProtectSystem = "strict";
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      RestrictRealtime = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      RemoveIPC = true;
      TasksMax = 1;
      UMask = 66;
      ProtectHostname = true;
      IPAddressDeny = "any";
      SystemCallFilter = [
        "~@clock"
        "@debug"
        "@module"
        "@mount"
        "@raw-io"
        "@reboot"
        "@swap"
        "@privileged"
        "@resources"
        "@cpu-emulation"
        "@obsolete"
        "setpriority"
        "set_mempolicy"
      ];
      WatchdogSec = 30;
      Restart = "on-failure";
      ExecStart = "${uksmd}/bin/uksmd";
    };
  };
}
