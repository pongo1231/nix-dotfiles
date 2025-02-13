{ sharePath }:
_: {
  services.samba = {
    enable = true;
    settings = {
      global = {
        owner = "unix only";
        permissions = "yes";
        security = "user";
        writable = "yes";
        "load printers" = "no";
        printing = "bsd";
        "printcap name" = "/dev/null";
        "disable spoolss" = "yes";
        "show add printer wizard" = "no";
        "server multi channel support" = "yes";
        deadtime = 30;
        "use sendfile" = "yes";
        "min receivefile size" = 16384;
        "aio read size" = 1;
        "aio write size" = 1;
        "socket options" = "IPTOS_LOWDELAY TCP_NODELAY IPTOS_THROUGHPUT SO_RCVBUF=131072 SO_SNDBUF=131072";
        "allow insecure wide links" = "yes";
        "fruit:copyfile" = "yes";
        "smb compression" = "no";
      };

      public = {
        comment = "public";
        path = "${sharePath}";
        public = "yes";
        "create mask" = 777;
        "directory mask" = 777;
        "follow symlinks" = "yes";
        "wide links" = "yes";
      };
    };
  };
}
