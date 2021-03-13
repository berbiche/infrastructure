{ config, lib, pkgs, rootPath, ... }:

with lib;

let
  cfg = config.configurations.hosting.traefik;
  traefikCfg = config.services.traefik;

  inherit (traefikCfg) dataDir;

  entryPoints = {
    web = {
      address = ":80";
      # Cannot be an empty list
      # proxyProtocol.trustedIPs = [ "127.0.0.1/32" "::1/128" ];
      http.redirections.entryPoint = {
        to = "websecure";
        scheme = "https";
        permanent = true;
      };
      # http.middlewares = [ "compress" "autodetect" "security" ];
    };
    websecure = {
      address = ":443";
      # Cannot be an empty list
      # proxyProtocol.trustedIPs = [ "127.0.0.1/32" "::1/128" ];
      # http.middlewares = [ "compress" "autodetect" "security" ];
    };
    metrics = {
      address = ":8082";
    };
  };

  middlewares = {
    # Enables compression
    compress.compress = {};
    # Disable auto-detecting content-type header (recommended)
    autodetect.contentType.autoDetect = true;
    # Basic-Auth middleware
    auth.basicAuth.usersFile = config.sops.secrets."traefik-users".path;
    # Secure headers middleware
    security = {
      headers = {

        #   map $scheme $hsts_header {
        #       https "max-age=31536000; includeSubdomains; preload"
        #   }
        #   add_header Strict-Transport-Security $hsts_header

        # Remove origin information in referrer header
        # Minimize information leaked to other domains
        referrerPolicy = "origin-when-cross-origin";
        # Disable embedding as a frame
        frameDeny = true;
        # Prevent injection of code in other mime types (XSS Attacks)
        contentTypeNosniff = true;
        # Enable XSS protection of the browser.
        browserXssFilter = true;
        # Enable CSP for your services.
        # contentSecurityPolicy = "default-src 'self'; script-src 'self'; object-src 'none'; base-uri 'self';";
        # contentSecurityPolicy = "default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self'; style-src 'self'; base-uri 'self'; form-action 'self'";
      };
    };
  };

  certificateConfig = {
    certificatesResolvers.cloudflare.acme = {
      email = "nic.berbiche@gmail.com";
      storage = "${config.services.traefik.dataDir}/acme.json";
      #caServer = "https://acme-v02.api.letsencrypt.org/directory";
      # caServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
      # tlsChallenge = {};
      dnsChallenge = {
        provider = "cloudflare";
        resolvers = [ "1.1.1.1:53" "8.8.8.8:53" /*"[2606:4700:4700::64]:53" "[2606:4700:4700::6400]:53"*/ ];
      };
    };
  };
in
{
  options.configurations.hosting.traefik = {
    enable = mkEnableOption "Traefik reverse proxy";
    enableACME = mkEnableOption "ACME certificate configuration";
    domain = mkOption {
      type = types.str;
      description = ''
        Root domain for Traefik's dashboard.
        Traefik will listen on `traefik.''${domain}`.
      '';
    };
  };



  config.sops.secrets."cloudflare-txt" = mkIf cfg.enable {
    format = "binary";
    owner = config.users.users.traefik.name;
    group = traefikCfg.group;
    sopsFile = rootPath + "/secrets/tq.rs/cloudflare.txt";
  };
  config.sops.secrets."traefik-users" = mkIf cfg.enable {
    format = "binary";
    # mode = "0440";
    owner = config.users.users.traefik.name;
    group = traefikCfg.group;
    sopsFile = rootPath + "/secrets/tq.rs/traefik.txt";
  };
  config.systemd.services.traefik.serviceConfig = mkIf cfg.enable {
    EnvironmentFile = config.sops.secrets."cloudflare-txt".path;
    SupplementaryGroups = [ config.users.groups.keys.name ];
  };

  config.networking.firewall = mkIf cfg.enable {
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPorts = [ 80 443 ];
  };

  config.services.traefik = mkIf cfg.enable {
    enable = true;

    staticConfigOptions = {
      # Let's log to the Systemd journal instead
      log = {
        # filePath = "${dataDir}/traefik.log";
        # format = "json";
        level = "DEBUG";
      };
      accessLog = {
        # filePath = "${dataDir}/access.log";
        format = "json";
      };

      global.checkNewVersion = true;

      api.dashboard = true;

      metrics.prometheus = {
        entryPoint = "metrics";
      };

      inherit entryPoints;
    } // optionalAttrs cfg.enableACME certificateConfig
      // {

      };

    dynamicConfigOptions = {
      http = {
        middlewares = middlewares // {
          redirect-dashboard.replacePathRegex = {
            regex = "^/dashboard$";
            replace = "/dashboard/";
          };
        };

        routers = {
          my-api = {
            rule = "Host(`traefik.${cfg.domain}`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))";
            entryPoints = [ "web" "websecure" ];
            service = "api@internal";
            middlewares = [ "auth" "redirect-dashboard" ];
          } // optionalAttrs cfg.enableACME {
            tls.certResolver = "cloudflare";
          };
          plex = {
            rule = "Host(`plex.tq.rs`)";
            entryPoints = [ "web" "websecure" ];
            # middlewares = [ "compress" ];
            service = "plex";
          } // optionalAttrs cfg.enableACME {
            tls.certResolver = "cloudflare";
          };
          tautulli = {
            rule = "Host(`tautulli.tq.rs`)";
            entryPoints = [ "web" "websecure" ];
            # middlewares = [ "compress" ];
            service = "tautulli";
          } // optionalAttrs cfg.enableACME {
            tls.certResolver = "cloudflare";
          };
        };
        services.plex = let
          plexPort = 32000;
        in {
          loadBalancer = {
            servers = [
              { url = "http://apoc.node.tq.rs:${toString plexPort}/"; }
            ];
          };
          healthCheck = {
            path = "/web/index.html";
            port = plexPort;
            interval = "15s";
            timeout = "3s";
          };
        };
        services.tautulli = let
          tautulliPort = config.services.tautulli.port;
        in {
          loadBalancer = {
            servers = [
              { url = "http://apoc.node.tq.rs:${toString tautulliPort}/"; }
            ];
          };
          healthCheck = {
            path = "/";
            port = tautulliPort;
            interval = "15s";
            timeout = "3s";
          };
        };
      };
    };
  };
}
