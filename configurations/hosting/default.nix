{ config, lib, pkgs, ... }:

let
  cfg = config.configurations.hosting;
  domain = config.networking.domain;
in
{
  imports = [
    ./acme.nix
    ./nginx.nix
    ./geoip.nix
  ];

  options.configurations.hosting.enable = lib.mkEnableOption "hosting configuration";

  config = {
    services.nginx.virtualHosts = {
      "${domain}" = {
        default = true;
      };
    };
  };
}
