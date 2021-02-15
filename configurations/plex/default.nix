{ config, lib, pkgs, ... }:

let
  cfg = config.configurations.plex;

  sslDirectoryFor = x: config.security.acme.certs."${x}".directory;

  defaults = [
    "defaults"
    "ro"
    "addr=192.168.0.52"
    "noauto"
    "x-systemd.automount"
    "x-systemd.device-timeout=10"
    "noatime"
    "timeo=10"
  ];
in
{
  options.configurations.plex.enable = lib.mkEnableOption "plex configuration";

  config = lib.mkIf cfg.enable {
    services.plex = {
      enable = true;
    };

    networking.firewall = {
      # Default port
      allowedTCPPorts = [ 32400 ];
      # AVAHI, Network Discovery, etc.
      allowedUDPPorts = [ 5353 32410 32412 32413 32414 ];
    };

    fileSystems."/metacortex" = {
      device = "zion:/mnt/metacortex";
      fsType = "nfs";
      noCheck = true;
      options = defaults;
    };

    users.groups.mediaserver = {
      gid = 950;
      members = [ config.services.plex.user ];
    };

    services.nginx.virtualHosts."plex.${config.networking.domain}" = {
      useACMEHost = "plex.${config.networking.domain}";
      sslCertificate = "${sslDirectoryFor "plex.${config.networking.domain}"}/full.pem";
      locations."/" = {
        proxyPass = "http://127.0.0.1:32401";
        proxyWebsockets = true;
      };
      extraConfig = ''
        ${config.services.nginx.defaultServerBlock}
      '';
    };
  };
}
