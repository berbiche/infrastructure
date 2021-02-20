{ config, lib, pkgs, rootPath, ... }:

let
  nginxVhosts = {
    "www.tq.rs" = {
      globalRedirect = "tq.rs";
    };
    "tq.rs" = {
      default = true;
    };
    "sonarr.tq.rs" = {
      locations."/ws" = {
        priority = 999;
        proxyPass = "https://media.tq.rs:443";
        proxyWebsockets = true;
      };
      locations."/" = {
        priority = 1000;
        proxyPass = "https://media.tq.rs:443";
      };
    };
  };
in
{
  options.configurations."tq.rs".enable = lib.mkEnableOption "tq.rs domain configuration and stuff";

  config = lib.mkIf config.configurations."tq.rs".enable {
    configurations.hosting.enable = true;

    sops.secrets.ddclient = {
      format = "binary";
      sopsFile = rootPath + "/secrets/tq.rs/ddclient.conf";
    };
    services.ddclient = {
      enable = true;
      configFile = config.sops.secrets.ddclient.path;
    };
    systemd.services.ddclient = {
      # For `dig`
      path = [ pkgs.dnsutils ];
      serviceConfig = {
        PrivateTmp = true;
      };
    };

    services.nginx.virtualHosts = nginxVhosts;
  };
}
