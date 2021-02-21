{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.configurations.hosting;

  inherit (config.services.traefik) dataDir;

  entryPoints = {
    http = {
      address = ":80";
      proxyProtocol = {};
    };
    https = {
      address = ":443";
      proxyProtocol = {};
    };
  };

  certificateConfig = {
    certificatesResolvers.myresolver.acme = {
      email = "nic.berbiche@gmail.com";
      storage = "acme.json";
      #caServer = "https://acme-v02.api.letsencrypt.org/directory";
      caServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
      tlsChallenge = {
        entryPoint = "https";
      };
      dnsChallenge = {
        provider = "cloudflare";
        resolvers = [ "1.0.0.1:53" "8.8.8.8:53" "[2606:4700:4700::64]:53" "[2606:4700:4700::6400]:53" ];
      };
    };
  };
in
{
  config.sops.secrets = mkIf cfg.enable (genAttrs [ "cloudflare-env" "traefik-users" ] (name: {
    format = "binary";
    owner = "traefik";
    group = config.services.traefik.group;
    sopsFile = rootPath + "/secrets/tq.rs/" + replaceStrings [ "-" "users" ] [ "." "txt" ] name;
  }));

  config.services.traefik = mkIf cfg.enable {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    enableReload = true;

    staticConfigOptions = {
      api.dashboard = true;
      http.routers.api = {
        rule = "Host(`traefik.${domain}`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))";
        service = "api@internal";
        middlewares = [ "auth" ];
      };
      http.middlewares.auth.basicAuth.usersFile = config.sops.secrets."traefik-users".path;
    } // entryPoints
      // optionalAttrs cfg.enableACME certificateConfig
      // {

      };


    # The host is a .dev domain, so HSTS is required
    commonHttpConfig = ''
      # The domain is a `.dev` domain, so HSTS is required
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

    defaultServerBlock = ''
      access_log /var/log/nginx/json_access.log json_analytics;
    '';
  };

  config.systemd.services.traefik.serviceConfig = {
    EnvironmentFile = config.sops.secrets."cloudflare-env".path;
  };

  config.networking.firewall = mkIf cfg.enable {
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPorts = [ 80 443 ];
  };
}
