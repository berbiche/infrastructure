{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  networking.hostName = "mouse";
  networking.domain = "tq.rs";

  configurations.qemu-node = {
    enable = true;
    VLAN-1-ipv4CIDR = "192.168.0.6/24";
    VLAN-42-ipv4CIDR = "192.168.42.6/24";
  };
}
