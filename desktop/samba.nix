{ pkgs
, ...
}:
{
  services.samba = {
    enable = true;
    configText = ''
      [global]
      security = user
      map to guest = bad user
      guest account = guest
      load printers = no
      printing = bsd
      printcap name = /dev/null
      disable spoolss = yes
      show add printer wizard = no
      server multi channel support = yes
      deadtime = 30
      use sendfile = yes
      min receivefile size = 16384
      aio read size = 1
      aio write size = 1
      socket options = IPTOS_LOWDELAY TCP_NODELAY IPTOS_THROUGHPUT SO_RCVBUF=131072 SO_SNDBUF=131072
      min protocol = SMB2
      max protocol = SMB3
      client min protocol = SMB2
      client max protocol = SMB3
      client ipc min protocol = SMB2
      client ipc max protocol = SMB3
      server min protocol = SMB2
      server max protocol = SMB3
      smb ports = 445
      allow insecure wide links = yes

      [guest]
      comment = guest
      path = /media/ssd/public
      public = yes
      only guest = yes
      writable = yes
      printable = no
      inherit permissions = yes
      follow symlinks = yes
      wide links = yes
    '';
  };

  users = {
    users.guest = {
      isNormalUser = true;
      createHome = false;
      shell = pkgs.shadow;
    };
  };
}
