{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.configurations.plex;
  plexCfg = config.services.plex;
in
{
  options.configurations.plex.enable = lib.mkEnableOption "plex configuration";
  options.configurations.plex.domain = lib.mkOption {
    type = lib.types.str;
    default = "plex.tq.rs";
    example = "plex.example.com";
    description = "The domain Plex will be bound to by Traefik";
  };
  options.configurations.plex.uid = lib.mkOption {
    type = lib.types.numbers.nonnegative;
  };
  options.configurations.plex.gid = lib.mkOption {
    type = lib.types.numbers.nonnegative;
  };
  options.configurations.plex.package = lib.mkPackageOption pkgs "plex" { };

  config = lib.mkIf cfg.enable {
    services.plex = {
      enable = true;
      openFirewall = false;
      package = cfg.package;
    };

    networking.firewall = {
      # Default port
      allowedTCPPorts = [ 32400 ];
      # AVAHI, Network Discovery, etc.
      allowedUDPPorts = [ 5353 32410 32412 32413 32414 ];
    };
    networking.hosts = {
      "127.0.0.1" = [ cfg.domain ];
      "::1" = [ cfg.domain ];
    };
    systemd.tmpfiles.rules = [
      "d '${plexCfg.dataDir}' - ${plexCfg.user} ${plexCfg.group} - -"
    ];

    users.users.${plexCfg.user} = {
      uid = lib.mkForce cfg.uid;
      isSystemUser = true;
    };
    users.groups.${plexCfg.group}.gid = lib.mkForce cfg.gid;
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
