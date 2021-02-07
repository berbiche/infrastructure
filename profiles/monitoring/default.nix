{ config, lib, pkgs, ... }:

{
  services.grafana = {
    enable = true;
    domain = "grafana.cloud.normie.dev";
  };

  services.nginx.virtualHosts.${config.services.grafana.domain} = {
    locations."/" = {
      proxyPass = "http://127.0.0.1/${toString config.services.grafana.port}";
      proxyWebsockets = true;
    };
  };
}
