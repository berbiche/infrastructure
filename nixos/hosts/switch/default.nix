{ config, lib, pkgs, modulesPath, rootPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  sops.defaultSopsFile = rootPath + "/secrets/keanu.yaml";

  networking.hostName = "switch";
  networking.domain = "node.tq.rs";

  configurations.torrents.enable = true;
  configurations.torrents.qbittorrent = {
    downloadDirectory = "/mediaserver";
  };

  configurations.qemu-node = {
    enable = true;
    dnsServers = [ "192.168.42.6" "192.168.42.1" ];
    VLAN-42-gateway = "192.168.42.1";
    VLAN-42-ipv4CIDR = "192.168.42.8/24";
  };
}
