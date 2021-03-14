{ config, lib, pkgs, rootPath, ... }:

with lib;

let
  cfgHosting = config.configurations.hosting;
  cfg = cfgHosting.traefik;
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
      http.middlewares = [ "compress" "autodetect" "security" ];
    };
    websecure = {
      address = ":443";
      # Cannot be an empty list
      # proxyProtocol.trustedIPs = [ "127.0.0.1/32" "::1/128" ];
      http.middlewares = [ "compress" "autodetect" "security" ];
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

        # My domain has been preloaded to the HSTS list for a long time
        stsIncludeSubdomains = true;
        stsPreload = true;
        forceSTSHeader = true;
        # Enable CSP for your services.
        # contentSecurityPolicy = "default-src 'self'; script-src 'self'; object-src 'none'; base-uri 'self';";
        # contentSecurityPolicy = "default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self'; style-src 'self'; base-uri 'self'; form-action 'self'";
      };
    };
    redirect-dashboard.replacePathRegex = {
      regex = "^/dashboard$";
      replacement = "/dashboard/";
    };
    forward-auth.forwardAuth = {
      address = "http://localhost:4181";
      authResponseHeaders = ["X-Forwarded-User"];
      trustForwardHeader = true;
    };
    plex-cors.headers = {
      accessControlAllowMethods = [
        "GET"
        "OPTIONS"
        "PUT"
      ];
      accessControlAllowOriginList = [
        "https://app.plex.tv"
      ];
    };
  };

  certificateConfig = {
    certificatesResolvers.cloudflare.acme = {
      email = config.security.acme.email;
      storage = "${config.services.traefik.dataDir}/acme.json";
      caServer = config.security.acme.server;
      # tlsChallenge = {};
      dnsChallenge = {
        provider = "cloudflare";
        resolvers = [ "1.1.1.1:53" "8.8.8.8:53" "[2606:4700:4700::64]:53" "[2606:4700:4700::6400]:53" ];
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
    enableForwardAuth = mkEnableOption "forward authentication with Traefik Forward Auth running in podman";
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

    interfaces.ens19 = {
      allowedTCPPorts = [ 8082 ];
      allowedUDPPorts = [ 8082 ];
    };
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
      tls.options.default = {
        # Enable Strict SNI checking to disable serving hosts
        # that do not have a matching certificate
        sniStrict = true;
        minVersion = "VersionTLS12";
      };

      http = {
        inherit middlewares;

        routers = {
          dashboard = {
            rule = "Host(`traefik.${cfg.domain}`)";#" && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))";
            entryPoints = [ "websecure" ];
            service = "api@internal";
            middlewares = [ "redirect-dashboard" ] ++ (
              if cfg.enableForwardAuth
              then [ "forward-auth" ]
              else [ "auth" ]);
          } // optionalAttrs cfg.enableACME {
            tls.certResolver = "cloudflare";
            tls.domains = [{
              main = cfg.domain;
              sans = [ "traefik.${cfg.domain}" "auth.tq.rs" ];
            }];
          };
          plex = {
            rule = "Host(`plex.${cfg.domain}`)";
            entryPoints = [ "web" "websecure" ];
            middlewares = [ "plex-cors" ];
            service = "plex";
          } // optionalAttrs cfg.enableACME {
            tls.certResolver = "cloudflare";
          };
          tautulli = {
            rule = "Host(`tautulli.${cfg.domain}`)";
            entryPoints = [ "web" "websecure" ];
            middlewares = [ "forward-auth" ];
            service = "tautulli";
          } // optionalAttrs cfg.enableACME {
            tls.certResolver = "cloudflare";
          };
          traefik-forward-auth = {
            rule = "Host(`auth.tq.rs`)";
            entryPoints = [ "websecure" ];
            service = "traefik-forward-auth";
            middlewares = [ "forward-auth" ];
          } // optionalAttrs cfg.enableACME {
            tls.certResolver = "cloudflare";
          };
        };
        services.plex = let
          plexPort = 32400;
        in {
          loadBalancer = {
            servers = [
              { url = "http://apoc.node.tq.rs:${toString plexPort}/"; }
            ];
            healthCheck = {
              path = "/web/index.html";
              port = plexPort;
              interval = "15s";
              timeout = "3s";
            };
          };
        };
        services.tautulli = let
          tautulliPort = config.services.tautulli.port;
        in {
          loadBalancer = {
            servers = [
              { url = "http://apoc.node.tq.rs:${toString tautulliPort}/"; }
            ];
            healthCheck = {
              path = "/";
              port = tautulliPort;
              interval = "15s";
              timeout = "3s";
            };
          };
        };
        services.traefik-forward-auth = {
          loadBalancer = {
            servers = [{ url = "http://localhost:4181/"; }];
            healthCheck  ={
              path = "/";
              port = 4181;
              interval = "15s";
              timeout = "3s";
            };
          };
        };
      };
    };
  };

  # https://vincent.bernat.ch/fr/blog/2020-docker-nixos-isso
  # https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-dockerTools
  # nix run nixpkgs#nix-prefetch-docker -- --image-name thomseddon/traefik-forward-auth --image-tag 2
  config.virtualisation.oci-containers = let
    dockerImage = pkgs.dockerTools.pullImage {
      imageName = "thomseddon/traefik-forward-auth";
      imageDigest = "sha256:69a2c985d2c518b6f0e77161a98628a148a5d964e4e84fc52cc62e19bb4da634";
      finalImageName = "thomseddon/traefik-forward-auth";
      finalImageTag = "2";
      sha256 = "114c1bgzav6ahs5xbpk054m6sqwc4238b0k0xjmgxfi0szq076ri";
    };
    # Unused because environment secrets cannot be injected as a file
    configFile = pkgs.writeText "traefik-forward-auth-config.txt" ''
      auth-host = auth.tq.rs
      port = 4181
      default-provider = google
      cookie-domain = tq.rs
      ${optionalString false "domain = tq.rs, normie.dev"}
      whitelist = nic.berbiche@gmail.com, nicolas@normie.dev
      match-whitelist-or-domain = true
    '';
  in mkIf (cfg.enable && cfg.enableForwardAuth) {
    backend = "podman";
    containers = {
      traefik-forward-auth = {
        image = "thomseddon/traefik-forward-auth";
        imageFile = dockerImage;
        ports = [ "127.0.0.1:4181:4181" ];
        volumes = [ "${config.sops.secrets."traefik-forward-auth.txt".path}:/traefik-forward-auth-config.txt:ro" ];
        cmd = [
          "--config=/traefik-forward-auth-config.txt"
        ];
        autoStart = true;
      };
    };
  };

  config.sops.secrets."traefik-forward-auth.txt" = mkIf (cfg.enable && cfg.enableForwardAuth) {
    format = "binary";
    mode = "0400";
    sopsFile = rootPath + "/secrets/tq.rs/traefik-forward-auth.txt";
  };

  # Inject our environment file -> doesn't work, requires podman --env-host=true which we can't pass
  # config.systemd.services."podman-traefik-forward-auth" = mkIf (cfg.enable && cfg.enableForwardAuth) {
  #   serviceConfig.EnvironmentFile = config.sops.secrets."traefik-forward-auth.txt".path;
  # };
}
