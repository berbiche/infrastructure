{ config, lib, pkgs, ... }:

let
  inherit (lib) escapeShellArgs literalExample mkEnableOption mkIf mkOption types;

  cfg = config.services.promtail;

  configurationType = pkgs.formats.yaml { };

in {
  options.services.promtail = {
    enable = mkEnableOption "promtail";

    user = mkOption {
      type = types.str;
      default = "promtail";
      description = ''
        User under which the Promtail service runs.
      '';
    };

    group = mkOption {
      type = types.str;
      default = "promtail";
      description = ''
        Group under which the Promtail service runs.
      '';
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/promtail";
      description = ''
        Specify the directory for Promtail.
      '';
    };

    supplementaryGroups = mkOption {
      type = types.listOf types.str;
      default = [ "systemd-journald" ];
      description = ''
        Supplementary groups for the Promtail systemd service.
      '';
    };

    configuration = mkOption {
      type = configurationType.type;
      default = {};
      description = ''
        Specify the configuration for Promtail in Nix.
      '';
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Specify a configuration file that Promtail should use.
      '';
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [];
      example = literalExample [ "--server.http-listen-port=3101" ];
      description = ''
        Specify a list of additional command line flags,
        which get escaped and are then passed to Promtail.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = (
        (cfg.configuration == {} -> cfg.configFile != null) &&
        (cfg.configFile != null -> cfg.configuration == {})
      );
      message  = ''
        Please specify either
        'services.promtail.configuration' or
        'services.promtail.configFile'.
      '';
    }];

    users.groups.${cfg.group} = { };
    users.users.${cfg.user} = {
      description = "Promtail Service User";
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
      isSystemUser = true;
    };

    systemd.services.promtail = {
      description = "Promtail Service Daemon";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = let
        conf = if cfg.configFile == null
               then configurationType.generate "promtail.yaml" cfg.configuration
               else cfg.configFile;
      in
      {
        ExecStart = "${pkgs.grafana-loki}/bin/promtail --config.file=${conf} ${escapeShellArgs cfg.extraFlags}";
        User = cfg.user;
        Group = cfg.group;
        SupplementaryGroups = cfg.supplementaryGroups;
        Restart = "always";
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "full";
        DevicePolicy = "closed";
        RestrictSUIDSGID = true;
        NoNewPrivileges = true;
        WorkingDirectory = cfg.dataDir;
      };
    };
  };
}
