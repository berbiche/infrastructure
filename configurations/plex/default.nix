{ config, lib, pkgs, ... }:

let
  cfg = config.configurations.plex;
  plexCfg = config.services.plex;
  tautulliCfg = config.services.tautulli;

  plexPort = 32400;

  sslDirectoryFor = x: config.security.acme.certs."${x}".directory;

  defaults = [
    "defaults"
    "ro"
    "addr=192.168.0.4"
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
  options.configurations.plex.domain = lib.mkOption {
    type = lib.types.str;
    example = "plex.example.com";
    description = "The domain Plex will be bound to by Traefik";
  };

  config = lib.mkIf cfg.enable {
    services.plex = {
      enable = true;
      openFirewall = false;
    };

    services.tautulli = rec {
      enable = true;
      user = "tautulli";
      group = "tautulli";
      dataDir = "/var/lib/tautulli";
      configFile = "${dataDir}/config.ini";
    };

    networking.firewall = {
      # Default port
      allowedTCPPorts = [ 32400 ];
      # AVAHI, Network Discovery, etc.
      allowedUDPPorts = [ 5353 32410 32412 32413 32414 ];
    };
    networking.hosts = {
      "127.0.0.1" = [ "plex.tq.rs" "tautulli.tq.rs" "traefik.tq.rs" ];
      "::1" = [ "plex.tq.rs" "tautulli.tq.rs" "traefik.tq.rs" ];
    };

    fileSystems."/metacortex" = {
      device = "zion.lan:/mnt/metacortex";
      fsType = "nfs";
      noCheck = true;
      options = defaults;
    };
    fileSystems."/mediaserver" = {
      device = "/metacortex";
      fsType = "none";
      noCheck = true;
      options = [
        "bind"
        "defaults"
        "x-systemd.requires=/metacortex"
        "x-systemd.automount"
      ];
    };

    # systemd.services.plex.serviceConfig = {
    #   SupplementaryGroups = [ config.users.groups.mediaserver.name ];
    # };

    systemd.tmpfiles.rules = [
      "d '${plexCfg.dataDir}' - ${plexCfg.user} ${plexCfg.group} - -"
    ];

    users.users.${tautulliCfg.user} = {
      uid = 951;
      isSystemUser = true;
      group = tautulliCfg.group;
    };
    users.groups.${tautulliCfg.group} = {
      gid = 951;
    };
    users.users.${plexCfg.user}.uid = lib.mkForce 950;
    users.groups.${plexCfg.group}.gid = lib.mkForce 950;
    # users.users.${plexCfg.user}.extraGroups = [ config.users.groups.mediaserver.name ];
    # users.users.mediaserver = {
    #   uid = 950;
    #   isSystemUser = true;
    # };
    # users.groups.mediaserver = {
    #   gid = 950;
    #   members = [ plexCfg.user ];
    # };

    services.traefik.dynamicConfigOptions = {
      http.routers.plex = {
        rule = "Host(`${cfg.domain}`)";
        entryPoints = [ "websecure" ];
        # middlewares = [ "compress" ];
        service = "plex";
      };
      http.routers.tautulli = {
        rule = "Host(`tautulli.tq.rs`)";
        entryPoints = [ "websecure" ];
        # middlewares = [ "compress" ];
        service = "tautulli";
      };
      http.services.plex = {
        loadBalancer = {
          servers = [
            { url = "http://[::]:${toString plexPort}/"; }
          ];
        };
        healthCheck = {
          path = "/web/index.html";
          port = plexPort;
          interval = "15s";
          timeout = "3s";
        };
      };
      http.services.tautulli = {
        loadBalancer = {
          servers = [
            { url = "http://[::1]:${toString tautulliCfg.port}/"; }
          ];
        };
        healthCheck = {
          path = "/";
          port = tautulliCfg.port;
          interval = "15s";
          timeout = "3s";
        };
      };
    };
  };
}
