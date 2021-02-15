{ config, lib, pkgs, ... }:

let
  cfg = config.configurations.monitoring;
  grafanaDomain = config.services.grafana.domain;
  sslDirectoryFor = x: config.security.acme.certs."${x}".directory;
in
{
  imports = [
    ./grafana.nix
    ./loki.nix
    ./prometheus.nix
    ./promtail.nix
  ];

  options.configurations.monitoring.enable = lib.mkEnableOption "monitoring configuration";

  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts."${grafanaDomain}" = {
      useACMEHost = "cloud.${config.networking.domain}";
      sslCertificate = "${sslDirectoryFor "cloud.${config.networking.domain}"}/full.pem";
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.grafana.port}";
        proxyWebsockets = true;
      };
      extraConfig = ''
        ${config.services.nginx.defaultServerBlock}
      '';
    };
  };
}
