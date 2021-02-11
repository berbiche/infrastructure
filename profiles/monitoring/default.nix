{ config, lib, pkgs, ... }:

let
  domain = config.services.grafana.domain;
in
{
  imports = [
    ./grafana.nix
    ./loki.nix
    ./prometheus.nix
  ];

  services.nginx.virtualHosts.${domain} = {
    locations."/" = {
      proxyPass = "http://127.0.0.1/${toString config.services.grafana.port}";
      proxyWebsockets = true;
    };
  };
}
