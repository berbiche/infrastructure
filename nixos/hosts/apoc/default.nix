{ config, lib, pkgs, modulesPath, rootPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # sops.defaultSopsfile = rootPath + "/secrets/keanu.yaml";

  networking.hostName = "apoc";
  networking.domain = "node.tq.rs";

  configurations.qemu-node = {
    enable = true;
    VLAN-42-gateway = "192.168.42.1";
    VLAN-42-ipv4CIDR = "192.168.42.7/24";
    dnsServers = [ "192.168.42.6" "192.168.42.1" ];
  };

  configurations.plex.enable = true;
}
