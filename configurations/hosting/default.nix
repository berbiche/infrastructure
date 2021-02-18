{ config, lib, pkgs, ... }:

let
  cfg = config.configurations.hosting;
  domain = config.networking.domain;
in
{
  imports = [
    # ./acme.nix
    ./nginx.nix
    ./geoip.nix
  ];

  options.configurations.hosting.enable = lib.mkEnableOption "hosting configuration";

  config = {
    security.acme.acceptTerms = true;
    security.acme.email = ;
    # Staging environment for test purposes
    security.acme.server = "https://acme-staging-v02.api.letsencrypt.org/directory";

    services.nginx.virtualHosts = {
      "${domain}" = {
        default = true;
      };
    };
  };
}
