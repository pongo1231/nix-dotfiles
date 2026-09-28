{
  inputs,
  module,
  config,
  pkgs,
  lib,
  withSecrets,
  ...
}:
withSecrets "pongo" { store = "zephyr.yaml"; } {
  "base/fprintPinHash" = {
    owner = "pongo";
    mode = "0400";
  };
}
// {
  imports = [
    inputs.igm5000.nixosModules.default

    (import (module /cpu/amd.nix) { curveOptimizerAllCore = -30; })
    (import (module /gpu) [
      "amd"
      #"nvidia"
    ])
    (module /libvirt.nix)
    #(import (module /samba.nix) { sharePath = "/home/pongo/Public"; })
    (import (module /snapper.nix) { })
    (module /printing.nix)
  ];

  boot = {
    initrd = {
      luks.devices."root" = {
        device = "/dev/disk/by-partlabel/NixOS";
        allowDiscards = true;
        bypassWorkqueues = true;
      };

      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usb_storage"
        "sd_mod"
      ];
    };

    binfmt.emulatedSystems = [
      "aarch64-linux"
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [
        "noatime"
        "lazytime"
        "compress-force=zstd"
      ];
    };

    "/boot" = {
      device = "/dev/nvme0n1p1";
      fsType = "vfat";
      options = [
        "noatime"
        "lazytime"
      ];
    };
  };

  services = {
    udev.extraRules = ''
      SUBSYSTEM=="kvmfr", OWNER="pongo", GROUP="wheel", MODE="0600"
    '';

    beesd.filesystems."-" = {
      spec = "/";
      hashTableSizeMB = 1024;
      extraOptions = [ "-c 1" ];
    };

    fprintd.enable = true;
  };

  /*
    security.pam.services.gdm-fingerprint.text = lib.mkForce (
      let
        pinCheck = pkgs.writeShellScript "pam-fingerprint-pin" ''
          set -u
          umask 077
          log=/tmp/pam-fingerprint-pin.debug
          : > "$log"
          pin=
          printf 'uid=%s\n' "$(${pkgs.coreutils}/bin/id -u)" >> "$log"
          IFS= read -r pin || :
          printf 'pin_len=%s\n' "$(printf '%s' "$pin" | ${pkgs.coreutils}/bin/wc -c)" >> "$log"
          if [ ! -r ${config.sops.secrets."base/fprintPinHash".path} ]; then
            printf 'secret=unreadable\n' >> "$log"
            exit 1
          fi
          stored=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."base/fprintPinHash".path}) || {
            printf 'secret=cat_failed\n' >> "$log"
            exit 1
          }
          printf 'stored_len=%s stored_prefix=%s\n' \
            "$(printf '%s' "$stored" | ${pkgs.coreutils}/bin/wc -c)" \
            "$(printf '%s' "$stored" | ${pkgs.coreutils}/bin/cut -c1-4)" >> "$log"
          got=$(printf '%s\n' "$pin" | ${pkgs.mkpasswd}/bin/mkpasswd -S "$(printf '%s' "$stored" | ${pkgs.gnused}/bin/sed 's/\$[^$]*$//')" -s 2>>"$log") || got=
          if [ -n "$pin" ] && [ "$got" = "$stored" ]; then
            printf 'verdict=MATCH\n' >> "$log"
            exit 0
          fi
          printf 'verdict=MISMATCH pin_sha256=%s\n' \
            "$(printf '%s' "$pin" | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -d' ' -f1)" >> "$log"
          exit 1
        '';
      in
      ''
        account include login

        auth required ${config.security.pam.package}/lib/security/pam_shells.so
        auth requisite ${config.security.pam.package}/lib/security/pam_nologin.so
        auth requisite ${config.security.pam.package}/lib/security/pam_faillock.so preauth
        auth required ${config.services.fprintd.package}/lib/security/pam_fprintd.so
        auth required ${config.security.pam.package}/lib/security/pam_exec.so expose_authtok ${pinCheck}
        auth required ${config.security.pam.package}/lib/security/pam_env.so conffile=/etc/pam/environment readenv=0
        auth [success=ok default=1] ${pkgs.gdm}/lib/security/pam_gdm.so
        auth optional ${pkgs.gnome-keyring}/lib/security/pam_gnome_keyring.so

        password required ${config.security.pam.package}/lib/security/pam_deny.so

        session include login
      ''
    );
  */
}
