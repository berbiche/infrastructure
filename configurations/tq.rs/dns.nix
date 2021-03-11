{ config, lib, pkgs, ... }:

let
  cfg = config.configurations."tq.rs";
in
{
  config = cfg.enable {
    services.coredns.enable = true;
    services.coredns.config = ''
      tq.rs:5053 {
        # Prometheus affects all server block
        prometheus localhost:9253
        cancel 1s
        forward . /etc/resolv.conf
        chaos
        health
        cache
        log
      }

      .lan:5053 {
        cancel 1s
        forward . /etc/resolv.conf
        chaos
        health
        cache
        log
      }

      .:5053 {
        forward . /etc/resolv.conf 8.8.8.8 1.1.1.1 1.0.0.1 9.9.9.9
        cache
      }
    '';

    services.prometheus.scrapeConfigs = [
      {
        job_name = "coredns";
        honor_labels = true;
        relabel_configs = [
          {
            action = "keep";
          }
        ];
        static_configs = [{
          targets = [ "127.0.0.1:9253" ];
        }];
      }
    ];

    services.nsd.enable = true;
    # services.nsd.
  };
}
