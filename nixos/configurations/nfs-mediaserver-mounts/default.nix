{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.configurations.nfs-mediaserver-mounts;
  defaultMountOptions = concatStringsSep "," cfg.defaultMountOptions;
in
{
  options.configurations.nfs-mediaserver-mounts = {
    enable = mkEnableOption "NFS mediaserver mounts";

    host = mkOption {
      type = types.str;
      example = "truenas.example.com";
    };

    mounts = mkOption {
      type = types.attrsOf (types.submodule {
        options.path = mkOption {
          type = types.str;
          example = "/mediaserver";
        };
        options.uid = mkOption {
          type = types.numbers.nonnegative;
          example = 950;
          description = "UID of the NFS mounts";
        };
        options.gid = mkOption {
          type = types.numbers.nonnegative;
          example = 950;
          description = "GID of the NFS mounts";
        };
      });
      example = {
        "/mnt/tank/media" = {
          path = "/mediaserver";
          uid = 950;
          gid = 950;
        };
      };
      description = ''
        NFS mounts to mount from the TrueNAS host.
        The attribute name is the remote directory and the attribute value
        is the local mount point.
      '';
    };

    mountRO = mkEnableOption "mounting the NFS shares readonly";

    defaultMountOptions = mkOption {
      type = types.listOf types.str;
      default = [
        "defaults"
        (if cfg.mountRO then "ro" else "rw")
        "nfsvers=3"
        "noauto"
        "x-systemd.automount"
        "noatime"
        "timeo=10"
        "retry=1000000"
      ];
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      systemd.tmpfiles.rules = flip mapAttrsToList cfg.mounts (_: localFS:
        "d ${escapeShellArg localFS.path} - ${toString localFS.uid} ${toString localFS.gid} - -"
      );
      boot.supportedFilesystems = [ "nfs" ];

      systemd.mounts = flip mapAttrsToList cfg.mounts (remoteFS: localFS: {
        # Move the constants below in another file
        what = "${cfg.host}:${remoteFS}";
        where = localFS.path;
        type = "nfs";
        options = defaultMountOptions;
        mountConfig.DirectoryMode = "770";
        wantedBy = [ "multi-user.target" ];
      });
    }
  ]);
}
