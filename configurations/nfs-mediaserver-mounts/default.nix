{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.configurations.nfs-mediaserver-mounts;
in
{
  options.configurations.nfs-mediaserver-mounts = {
    enable = mkEnableOption "NFS mediaserver mounts";

    host = mkOption {
      type = types.str;
      default = "192.168.42.5";
    };

    mounts = mkOption {
      type = types.attrsOf types.str;
      default = {
        "/metacortex/anime" = "/mnt/tank/anime";
        "/metacortex/movies" = "/mnt/tank/movies";
        "/metacortex/tv" = "/mnt/tank/tv";
      };
      description = ''
        NFS mounts to mount from the TrueNas host.
        The attribute name is the local directory
      '';
    };

    defaultMountOptions = mkOption {
      type = types.listOf types.str;
      default = [
        "defaults"
        "ro"
        "nfsvers=3"
        "noauto"
        "x-systemd.automount"
        "x-systemd.device-timeout=10"
        "noatime"
        "timeo=10"
        "retry=1000000"
      ];
    };
  };

  config = mkIf cfg.enable {
    systemd.mounts = lib.flip mapAttrsToList cfg.mounts (localFS: remoteFS: {
      # Move the constants below in another file
      what = "${cfg.host}:${remoteFS}";
      where = localFS;
      type = "nfs";
      options = lib.concatStringsSep "," cfg.defaultMountOptions;
      mountConfig.DirectoryMode = "770";
      wantedBy = [ "multi-user.target" ];
    });
  };
}
