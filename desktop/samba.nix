{ sharePath }:
{ pkgs
, ...
}:
{
  services.samba = {
    enable = true;
    settings = {
      global = {
        owner = "unix only";
        permissions = "yes";
        "create mask" = 0664;
        "directory mask" = 2755;
        "force create mode" = 0644;
        "force directory mode" = 2755;
        security = "user";
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
        "socket options" = "IPTOS_LOWDELAY TCP_NODELAY IPTOS_THROUGHPUT SO_RCVBUF = 131072 SO_SNDBUF=131072";
        "allow insecure wide links" = "yes";
      };

      public = {
        comment = "public";
        path = "${sharePath}";
        public = "yes";
        writable = "yes";
        printable = "no";
        permissions = "yes";
        "follow symlinks" = "yes";
        "wide links" = "yes";
      };
    };
  };
}

