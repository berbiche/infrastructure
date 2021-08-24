{ config, lib, pkgs, modulesPath, rootPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  sops.defaultSopsFile = rootPath + "/secrets/keanu.yaml";

  networking.hostName = "switch";
  networking.domain = "node.tq.rs";

  configurations.torrents.enable = false;
  configurations.torrents.qbittorrent = {
    downloadDirectory = "/mediaserver";
  };

  configurations.qemu-node = {
    enable = true;
    dnsServers = [ "10.97.42.6" "10.97.42.1" ];
    VLAN-42-gateway = "10.97.42.1";
    VLAN-42-ipv4CIDR = "10.97.42.8/24";
  };
}
