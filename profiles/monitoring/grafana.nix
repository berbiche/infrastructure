{ config, lib, pkgs, ... }:

{
  services.grafana = {
    enable = true;
    port = 2342;
    addr = "127.0.0.1";
    domain = "grafana.cloud.normie.dev";
  };
}
