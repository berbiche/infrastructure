{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.configurations.monitoring;
  inherit (config.services.loki) dataDir;
in
{
  # The `configuration` option is not mergeable so we use the definition from
  # unstable which has it (20.09 does not have it)
  disabledModules = [ "services/monitoring/loki.nix" ];
  imports = [ "${inputs.nixpkgs-unstable.outPath}/nixos/modules/services/monitoring/loki.nix" ];

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = ! lib.hasSuffix "/" dataDir;
      message = "services.loki.dataDir has a trailing slash";
    }];

    services.loki = {
      enable = true;

      configuration = {
        # auth_enabled = true;

        server.http_listen_port = 3100;
        server.grpc_listen_port = 0;

        ingester = {
          lifecycler = {
            address = "127.0.0.1";
            ring = {
              kvstore.store = "inmemory";
              replication_factor = 1;
            };
            final_sleep = "0s";
          };
          # Any chunk not receiving new logs in this time will be flushed
          chunk_idle_period = "1h";
          # All chunks will be flushed when they hit this age, default is 1h
          max_chunk_age = "1h";
          # Loki will attempt to build chunks up to 1.5MB, flushing first if chunk_idle_period or max_chunk_age is reached first
          chunk_target_size = 1048576;
          # Must be greater than index read cache TTL if using an index cache (Default index read cache TTL is 5m)
          chunk_retain_period = "30s";
          # Chunk transfers disabled
          max_transfer_retries = 0;
        };

        schema_config.configs = [{
          from = "2021-01-01";
          store = "boltdb-shipper";
          object_store = "filesystem";
          schema = "v11";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }];

        storage_config = {
          boltdb_shipper = {
            active_index_directory = "${dataDir}/boltdb-shipper-active";
            cache_location = "${dataDir}/boltdb-shipper-cache";
            # Can be increased for faster performance over longer query periods, uses more disk space
            cache_ttl = "24h";
            shared_store = "filesystem";
          };
          filesystem.directory = "${dataDir}/chunks";
        };

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
        };

        chunk_store_config.max_look_back_period = "0s";

        table_manager = {
          retention_deletes_enabled = false;
          retention_period = "0s";
        };
      };

    };
  };
}
