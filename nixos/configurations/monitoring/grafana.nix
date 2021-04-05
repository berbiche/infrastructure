{ config, lib, pkgs, ... }:

let
  cfg = config.configurations.monitoring;
in
{
  config = lib.mkIf cfg.enable {

    sops.secrets = lib.genAttrs [ "grafana-admin-pass" "grafana-secret-key"  ] (x: {
      owner = config.services.grafana.database.user;
      group = config.services.grafana.database.user;
    });

    services.grafana = {
      enable = true;
      port = 2342;
      addr = "127.0.0.1";
      domain = "grafana.cloud.${config.networking.domain}";

      security = {
        adminPasswordFile = config.sops.secrets.grafana-admin-pass.path;
        # Database encryption key
        secretKeyFile = config.sops.secrets.grafana-secret-key.path;
      };

      analytics.reporting.enable = lib.mkForce false;
    };
  };
}
