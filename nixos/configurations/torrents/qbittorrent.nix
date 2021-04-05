{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.configurations.torrents;
  cfgQbit = cfg.qbittorrent;
  webuiPort = 15000;
in
{
  options.configurations.torrents.qbittorrent = {
    port = mkOption {
      type = types.int;
      default = 31338;
    };

    uid = mkOption {
      type = types.int;
      default = config.configurations.nfs-mediaserver-mounts.uid;
    };

    gid = mkOption {
      type = types.int;
      default = config.configurations.nfs-mediaserver-mounts.gid;
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/qbittorrent";
    };

    downloadDirectory = mkOption {
      type = types.str;
      # default = "/mediaserver";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d '${cfgQbit.dataDir}' - ${toString cfgQbit.uid} ${toString cfgQbit.gid} - -"
    ];

    # systemd.services.qbittorrent = {
    #   description = "";
    #   after = [ "network.target" ];
    #   wantedBy = [ "multi-user.target" ];
    #   environment.CURL_CA_BUNDLE = config.environment.etc."ssl/certs/ca-certificates.crt".source;
    #   # qbittorrent-nox --profile=${qFolder} --relative-fastresume # fastresume files are relative to the profile directory
    #   serviceConfig = {

    #   };
    # };

    networking.firewall.allowedTCPPorts = [ cfgQbit.port webuiPort ];
    networking.firewall.allowedUDPPorts = [ cfgQbit.port ];

    users.users.qbittorrent = {
      isSystemUser = true;
      uid = cfgQbit.uid;
      group = "qbittorrent";
      extraGroups = [ "mediaserver" ];
    };
    users.groups.qbittorrent = {
      gid = cfgQbit.gid;
    };

    virtualisation.oci-containers.backend = "podman";
    virtualisation.oci-containers.containers.qbittorrent = let
    in {
      image = "linuxserver/qbittorrent";
      imageFile = pkgs.dockerTools.pullImage rec {
        imageName = "linuxserver/qbittorrent";
        imageDigest = "sha256:9c1a0a3853f46d3f68eb572069a33c91be5f5955e421503fa98aa2949f78931b";
        finalImageName = imageName;
        finalImageTag = "version-14.3.3.99202101191832-7248-da0b276d5ubuntu20.04.1";
        sha256 = "sha256-wPIfQUU22e7GgwWPNyTS/t91QrDJZN5UOeM2N1B4srM=";
      };

      volumes = [
        "${cfgQbit.dataDir}:/config"
        "${cfgQbit.downloadDirectory}:${cfgQbit.downloadDirectory}:rbind"
        "/dev/null:/downloads"
      ];

      # user = "${toString cfgQbit.uid}:${toString cfgQbit.gid}";

      ports = [
        "${toString webuiPort}:8080" # webui
        "${toString cfgQbit.port}:6881"
        "${toString cfgQbit.port}:6881/udp"
      ];

      environment = {
        PUID = toString cfgQbit.uid;
        PGID = toString cfgQbit.gid;
        WEBUI_PORT = "8080";
        TZ = config.time.timeZone;
      };
    };

    systemd.services.podman-qbittorrent = rec {
      requires = [
        "mediaserver-anime.mount"
        "mediaserver-tv.mount"
        "mediaserver-movies.mount"
      ];
      after = requires;
    };
  };
}
