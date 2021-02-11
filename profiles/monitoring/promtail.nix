{ config, lib, pkgs, ... }:

let
  generator = (pkgs.formats.yaml { }).generate;

  host = config.networking.hostname;

  lokiPort = config.services.loki.configuration.server.http_listen_port;
in
{
  services.promtail = lib.mkIf config.services.loki.enable {
    enable = true;

    supplementaryGroups = [
      config.services.nginx.group
      "systemd-journald"
    ];

    configuration = {
      server.http_listen_port = 17926;
      server.grpc_listen_port = 0;

      # Safe because it has its own private tmp
      positions.filename = "/tmp/positions.yaml";

      clients = [{
        url = "http://127.0.0.1:${toString lokiPort}/loki/api/v1/push";
      }];

      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              inherit host;
            };
          };
          relabel_configs = [{
            source_labels = [ "__journal__systemd_unit" ];
            target_abel = "unit";
          }];
        }
        {
          job_name = "pam";
          entry_parser = "raw";
          static_configs = [{
            targets = [ "localhost" ];
            labels = {
              job = "pam";
              inherit host;
            };
          }];
        }
      ];
    };
  };
}
