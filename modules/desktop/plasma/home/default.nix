{
  pkgs,
  ...
}:
{
  home = {
    file = {
      # Workaround for plasma-browser-integration
      ".mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json".source =
        "${pkgs.kdePackages.plasma-browser-integration}/lib/mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json";
    };

    packages = with pkgs.kdePackages; [ filelight ];
  };
}
