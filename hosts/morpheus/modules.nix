{ config, lib, pkgs, ... }:

{
  configurations.plex.enable = true;

  configurations."tq.rs".enable = true;

  configurations.hosting = {
    enable = true;

    traefik = {
      enable = true;
      enableACME = false;
      domain = "tq.rs";
    };
  };
}
