{ config, lib, pkgs, ... }:

let
  cfgCfg = config.configurations.monitoring;
  cfg = config.services.prometheus.exporters;
in
{
  config = lib.mkIf cfgCfg.enable {
    services.prometheus = {
      enable = true;
      port = 9001;

      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
        };
      };

      scrapeConfigs = [
        {
          job_name = "system";
          static_configs = [{
            targets = [ "127.0.0.1:${toString cfg.node.port}" ];
          }];
        }
      ];
    };

    systemd.services.prometheus-node-exporter.serviceConfig.DynamicUser = lib.mkForce true;
  };
}
