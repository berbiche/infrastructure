{ config, lib, pkgs, ... }:

{
  services.nginx = {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";


    # The host is a .dev domain, so HSTS is required
    commonHttpConfig = ''
      map $scheme $hsts_header {
          https "max-age=31536000; includeSubdomains; preload"
      }
      add_header Strict-Transport-Security $hsts_header

      # Enable CSP for your services.
      #add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;

      # Minimize information leaked to other domains
      add_header 'Referrer-Policy' 'origin-when-cross-origin'

      # Disable embedding as a frame
      add_header X-Frame-Options DENY

      # Prevent injection of code in other mime types (XSS Attacks)
      add_header X-Content-Type-Options nosniff;

      # Enable XSS protection of the browser.
      add_header X-XSS-Protection '1;mode=block'

      #proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
    '';
  };
}
