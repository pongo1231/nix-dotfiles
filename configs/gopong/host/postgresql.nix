{ ... }:
{
  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "nextcloud"
      "picsur"
    ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
      {
        name = "picsur";
        ensureDBOwnership = true;
      }
    ];
  };
}
