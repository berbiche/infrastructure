{ config, lib, pkgs, ... }:

let
  cfg = config.configurations."tq.rs";
in
{
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];

    services.coredns.enable = true;
    services.coredns.config = ''
      tq.rs {
        # Prometheus affects all server block
        prometheus localhost:9253
        cancel 1s
        file ${pkgs.writeText "coredns-tq-rs-zone" ''
          @       900 IN SOA   ns.tq.rs.   nicberbiche.gmail.com. (2021062501 3600 600 604800 600)
                  900 IN NS    ns

          ; A/AAAA records
          @                     900 IN A 10.97.42.6
          mouse.node            900 IN A 10.97.42.6
          apoc.node             900 IN A 10.97.42.7
          switch.node           900 IN A 10.97.42.8
          proxmox.node          900 IN A 10.97.42.4
          proxmox-morpheus.node 900 IN A 10.97.42.4
          proxmox-zion.node     900 IN A 10.97.42.3
          truenas.node          900 IN A 10.97.42.5

          ; CNAME records
          ns           900 IN CNAME @
          www          900 IN CNAME @
          traefik      900 IN CNAME @
          proxmox      900 IN CNAME @
          plex         900 IN CNAME @
          auth         900 IN CNAME @

          ; PTR records
          3            900 IN PTR   proxmox-zion.node.tq.rs
          4            900 IN PTR   proxmox.node.tq.rs
          4            900 IN PTR   proxmox-morpheus.node.tq.rs
          6            900 IN PTR   ns.tq.rs.
          6            900 IN PTR   traefik.tq.rs.
          6            900 IN PTR   proxmox.tq.rs.
          6            900 IN PTR   auth.tq.rs.
          6            900 IN PTR   plex.tq.rs.
          6            900 IN PTR   mouse.node.tq.rs.
          7            900 IN PTR   apoc.node.tq.rs.
          8            900 IN PTR   switch.node.tq.rs.
        ''} tq.rs 42.97.10.in-addr.arpa {
          reload 0
        }
        chaos
        health :8080
        errors
        cache
        log
      }

      lan {
        cancel 1s
        chaos
        log
        errors
        forward . 10.97.42.1
        cache
      }

      . {
        any
        # Forward to my router because of the dns adblock
        forward . 10.97.42.1 8.8.8.8 1.1.1.1 8.8.4.4 1.0.0.1 9.9.9.9 {
          prefer_udp
          policy sequential
        }
        errors
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
  };
}
