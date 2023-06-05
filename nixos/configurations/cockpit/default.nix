{ config, lib, pkgs, ... }:

let
  cfg = config.configurations.cockpit;
in
{
  options.configurations.cockpit = {
    enable = lib.mkEnableOption "cockpit";
    fqdn = lib.mkOption {
      type = lib.types.str;
      description = "cockpit origin FQDN";
      default = config.networking.fqdn;
    };
  };

  config = {
    services.cockpit = lib.mkIf cfg.enable {
      enable = true;
      openFirewall = true;

      settings = {
        WebService = {
          Origins = "https://${cfg.fqdn}:${toString config.services.cockpit.port}";
          LoginTo = false;
          AllowUnencrypted = false;
        };
        # Session.Banner = "/etc/issue";
      };
    };
  };
}
