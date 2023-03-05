{ config, inputs, lib, pkgs, ... }:

let
  cfg = config.configurations.cockpit;
in
{
  imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/services/monitoring/cockpit.nix" ];

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
      package = pkgs.packages.cockpit;
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
