{ config, lib, pkgs, ... }:

let
  cfg = config.configurations.hosting;
in
{
  imports = [
    # ./acme.nix
    # ./nginx.nix
    # ./geoip.nix
    ./traefik.nix
  ];

  options.configurations.hosting.enable = lib.mkEnableOption "hosting configuration";

  config = {
    security.acme.acceptTerms = true;
    security.acme.defaults.email = "nic.berbiche@gmail.com";
    # Staging environment for test purposes
    security.acme.defaults.server = "https://acme-v02.api.letsencrypt.org/directory";
    # security.acme.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
  };
}
