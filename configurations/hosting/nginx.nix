{ config, lib, pkgs, ... }:

let
  cfg = config.configurations.hosting;
in
{
  config.services.nginx = lib.mkIf cfg.enable {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    enableReload = true;

    logError = "/var/log/nginx/error.log";


    # The host is a .dev domain, so HSTS is required
    commonHttpConfig = let
      config = lib.concatMapStringsSep ",'\n" (x: "'\"${x}\": \"\$${x}\"") [
        "msec"
        "connection"
        "connect_requests"
        "pid"
        "request_id"
        "request_length"
        "remote_addr"
        "remote_user"
        "remote_port"
        "time_local"
        "time_iso8601"
        "request"
        "request_uri"
        "args"
        "status"
        "body_bytes_sent"
        "bytes_sent"
        "http_referer"
        "http_user_agent"
        "http_x_forwarded_for"
        "http_host"
        "server_name"
        "request_time"
        "upstream"
        "upstream_connect_time"
        "upstream_header_time"
        "upstream_response_time"
        "upstream_response_length"
        "upstream_cache_status"
        "ssl_protocol"
        "ssl_cipher"
        "scheme"
        "request_method"
        "server_method"
        "server_protocol"
        "pipe"
        "gzip_ratio"
        "http_cf_ray"
      ] #+ ",'\n'\"geoip_country_code\": \"$geoip2_data_country_code\"'";
        + "'";
    in ''
      log_format json_analytics escape=json '{'
        ${config}
      '}';

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

  config.services.promtail = lib.mkIf cfg.enable {
    configuration.scrape_configs = [
      {
        job_name = "system";
        pipeline_stages = [{
          replace = {
            expression = "(?:[0-9]{1,3}\\.)([0-9]{1,3})";
            replace = "***";
          };
        }];
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}" ];
          labels = {
            job = "nginx_access_log";
            host = config.networking.hostName;
            agent = "promtail";
            "__path__" = "/var/log/nginx/json_access.log";
          };
        }];
      }
    ];
  };
}
