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
          @       900 IN SOA   ns.tq.rs.   nicberbiche.gmail.com. (2021031305 3600 600 604800 600)
                  900 IN NS    ns.tq.rs.

          ; A/AAAA records
          @            900 IN A     192.168.0.6
          mouse.node   900 IN A     192.168.0.6
          apoc.node    900 IN A     192.168.0.7
          switch.node  900 IN A     192.168.0.8

          ; CNAME records
          ns           900 IN CNAME @
          www          900 IN CNAME @
          traefik      900 IN CNAME @
          plex         900 IN CNAME @
          tautulli     900 IN CNAME @
          qbittorrent  900 IN CNAME @
          rtorrent     900 IN CNAME @
          sonarr       900 IN CNAME @
          radarr       900 IN CNAME @
          jackett      900 IN CNAME @

          ; PTR records
          6            900 IN PTR   ns.tq.rs.
          6            900 IN PTR   www.tq.rs.
          6            900 IN PTR   traefik.tq.rs.
          6            900 IN PTR   auth.tq.rs.
          6            900 IN PTR   plex.tq.rs.
          6            900 IN PTR   qbittorrent.tq.rs.
          6            900 IN PTR   rtorrent.tq.rs.
          6            900 IN PTR   sonarr.tq.rs.
          6            900 IN PTR   radarr.tq.rs.
          6            900 IN PTR   jackett.tq.rs.
          6            900 IN PTR   mouse.node.tq.rs.
          7            900 IN PTR   apoc.node.tq.rs.
          8            900 IN PTR   switch.node.tq.rs.
        ''} tq.rs 42.168.192.in-addr.arpa 0.168.192.in-addr.arpa {
          reload 0
        }
        chaos
        health :8080
        cache
        log
      }
      # 192.168.0.0/24 192.168.42.0/24 {
      #   whoami
      # }

      lan {
        cancel 1s
        chaos
        log
        errors
        forward . 192.168.0.1
        cache
      }

      . {
        any
        forward . 8.8.8.8 1.1.1.1 8.8.4.4 1.0.0.1 9.9.9.9
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
