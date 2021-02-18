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

  inherit (config.networking) domain hostName;
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

    users.users.mediaserver = {
      uid = 950;
      isSystemUser = true;
    };
    users.groups.mediaserver = {
      gid = 950;
      members = [ config.services.plex.user ];
    };

    services.nginx.virtualHosts = let
      nginxConfig = {
        useACMEHost = "plex.${domain}";
        addSSL = true;
        sslCertificate = "${sslDirectoryFor "plex.${domain}"}/full.pem";
        locations."/" = {
          proxyPass = "http://127.0.0.1:32400";
          proxyWebsockets = true;
        };
        serverName = "plex.${domain}";
        serverAliases = [
          "plex.${hostName}"
          "plex.${hostName}.lan"
        ];
        extraConfig = ''
          ${config.services.nginx.defaultServerBlock}
        '';
      };
    in {
      "plex" = nginxConfig;
    };
  };
}
