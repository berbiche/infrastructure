{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.configurations.nfs-mediaserver-mounts;
in
{
  options.configurations.nfs-mediaserver-mounts = {
    enable = mkEnableOption "NFS mediaserver mounts";

    mediaserver.enableBindMount = mkEnableOption "bind mounting to /mediaserver every folder" // { default = true; };

    host = mkOption {
      type = types.str;
      default = "10.97.42.5";
    };

    uid = mkOption {
      type = types.int;
      default = 950;
      readOnly = true;
      description = "UID of the NFS mounts";
    };

    gid = mkOption {
      type = types.int;
      default = 950;
      readOnly = true;
      description = "GID of the NFS mounts";
    };

    mounts = mkOption {
      type = types.attrsOf types.str;
      default = {
        "/mediaserver" = "/mnt/tank/media";
      };
      description = ''
        NFS mounts to mount from the TrueNas host.
        The attribute name is the local directory.
        By default, a systemd tmpfiles rule is created for the
        the folder <path>/metacortex</path> to chown it to
        the specified GID and UID.
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
      systemd.tmpfiles.rules = let
        uid = toString cfg.uid;
        gid = toString cfg.gid;
      in [
        "d '/metacortex' - ${uid} ${gid} - -"
        "d '/mediaserver' - ${uid} ${gid} - -"
      ];
      boot.supportedFilesystems = [ "nfs" ];

      systemd.mounts = flip mapAttrsToList cfg.mounts (localFS: remoteFS: {
        # Move the constants below in another file
        what = "${cfg.host}:${remoteFS}";
        where = localFS;
        type = "nfs";
        options = concatStringsSep "," cfg.defaultMountOptions;
        mountConfig.DirectoryMode = "770";
        wantedBy = [ "multi-user.target" ];
      });
    }
    (mkIf cfg.mediaserver.enableBindMount {
      systemd.mounts = [{
        what = "/mediaserver";
        where = "/metacortex";
        type = "none";
        options = concatStringsSep "," [
          "bind"
          "defaults"
          "noauto"
          "x-systemd.requires-mounts-for=/mediaserver"
          "x-systemd.automount"
        ];
        mountConfig.DirectoryMode = "770";
        wantedBy = [ "multi-user.target" ];
      }];
      # systemd.mounts = flip mapAttrsToList cfg.mounts (localFS: _: {
      #   what = localFS;
      #   where = "/mediaserver/${builtins.baseNameOf localFS}";
      #   type = "none";
      #   options = concatStringsSep "," [
      #     "bind"
      #     "defaults"
      #     "noauto"
      #     "x-systemd.requires-mounts-for=${localFS}"
      #     "x-systemd.automount"
      #   ];
      #   mountConfig.DirectoryMode = "770";
      #   wantedBy = [ "multi-user.target" ];
      # });
    })
  ]);
}
