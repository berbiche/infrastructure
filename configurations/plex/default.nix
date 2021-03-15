{ config, lib, pkgs, ... }:

let
  cfg = config.configurations.plex;
  plexCfg = config.services.plex;
  tautulliCfg = config.services.tautulli;
in
{
  options.configurations.plex.enable = lib.mkEnableOption "plex configuration";
  options.configurations.plex.domain = lib.mkOption {
    type = lib.types.str;
    example = "plex.example.com";
    description = "The domain Plex will be bound to by Traefik";
  };

  config = lib.mkIf cfg.enable {
    configurations.nfs-mediaserver-mounts.enable = true;
    configurations.nfs-mediaserver-mounts.mountRO = true;
    configurations.nfs-mediaserver-mounts.mediaserver.enableBindMount = true;

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
      allowedTCPPorts = [ tautulliCfg.port 32400 ];
      # AVAHI, Network Discovery, etc.
      allowedUDPPorts = [ 5353 32410 32412 32413 32414 ];
    };
    networking.hosts = {
      "127.0.0.1" = [ "plex.tq.rs" "tautulli.tq.rs" ];
      "::1" = [ "plex.tq.rs" "tautulli.tq.rs" ];
    };
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
  };
}
