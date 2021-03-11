{ config, lib, pkgs, ... }:

let
  cfg = config.configurations.hosting;
  domain = config.networking.domain;
in
{
  imports = [
    # ./acme.nix
    # ./nginx.nix
    ./geoip.nix
    ./traefik.nix
  ];

  options.configurations.hosting.enable = lib.mkEnableOption "hosting configuration";

  config = {
    security.acme.acceptTerms = true;
    security.acme.email = "nic.berbiche@gmail.com";
    # Staging environment for test purposes
    security.acme.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
  };
}
