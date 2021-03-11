{ config, lib, pkgs, ... }:

let
  cfg = config.services.prometheus.exporters;
in
{
  services.prometheus = {
    enable = true;
    port = 9001;

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "systemd"
          "tcpstat"
          "conntrack"
          "diskstats"
          "entropy"
          "filefd"
          "filesystem"
          "loadavg"
          "meminfo"
          "netdev"
          "netstat"
          "nfs"
          "stat"
          "time"
          "vmstat"
          "logind"
          "thermal_zone"
          "interrupts"
          "ksmd"
        ];
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
}
