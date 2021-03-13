{ config, lib, pkgs, rootPath, ... }:

let
  cfg = config.configurations."tq.rs";
in
{
  imports = [ ./dns.nix ];

  options.configurations."tq.rs".enable = lib.mkEnableOption "tq.rs domain configuration and stuff";

  config = lib.mkIf cfg.enable {
    configurations.hosting.enable = true;
    configurations.plex.domain = "plex.tq.rs";

    sops.secrets.ddclient = {
      format = "binary";
      sopsFile = rootPath + "/secrets/tq.rs/ddclient.conf";
    };
    services.ddclient = {
      enable = false;
      configFile = config.sops.secrets.ddclient.path;
    };
    systemd.services.ddclient = {
      # For `dig`
      path = [ pkgs.dnsutils ];
      serviceConfig = {
        PrivateTmp = true;
      };
    };
  };
}
