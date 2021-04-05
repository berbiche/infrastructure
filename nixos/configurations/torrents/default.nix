{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.configurations.torrents;
in
{
  imports = [ ./qbittorrent.nix ];

  options.configurations.torrents.enable = mkEnableOption "torrent download software";

  config = mkIf cfg.enable {
    configurations.nfs-mediaserver-mounts.enable = true;
    configurations.nfs-mediaserver-mounts.mediaserver.enableBindMount = true;

    networking.firewall.allowedTCPPorts = [
      9117 # Jackett
      7878 # Radarr
      8989 # Sonarr
    ];

    # services.jackett.enable = true;
    # services.radarr.enable = true;
    # services.sonarr.enable = true;

  };
}
