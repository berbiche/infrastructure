{ config, lib, pkgs, ... }:

{
  networking.useDHCP = false;
  networking.useNetworkd = true;
  networking.firewall.logRefusedPackets = true;
  networking.firewall.logRefusedConnections = true;
  systemd.network.enable = true;
  services.resolved.enable = true;

  # Links: LAN & WAN (rename interface)
  systemd.network.links = lib.mapAttrs (n: v: {
    matchConfig.MACAddress = v.mac or "";
    linkConfig.Name = v.name;
    linkConfig.Description = v.description;
  }) {
    "10-lan" = {
      name = "lan";
      mac = "c8:0a:a9:04:3b:5e";
      description = "Local network";
    };
    "10-wan" = {
      name = "wan";
      mac = "c8:0a:a9:04:3b:5f";
      description = "Internet network";
    };
  };

  # VLANS : 1, 42
  # systemd.network.netdevs = lib.mapAttrs (n: v: {
  #   netdevConfig = removeAttrs v [ "VID" ];
  #   vlanConfig.Id = v.VID;
  # }) {
  #   "30-lan" = {
  #     Name = "lan.1";
  #     Kind = "vlan";
  #     VID = 1;
  #   };
  #   # "30-server" = {
  #   #   Name = "server.41";
  #   #   Kind = "vlan";
  #   #   vlan = 41;
  #   # };
  #   "30-wan" = {
  #     Name = "wan.42";
  #     Kind = "vlan";
  #     VID = 42;
  #   };
  # };

  # Networks: LAN (PVID 1), WAN (PVID 42)
  systemd.network.networks = let
    networkConfig = {
      DNSSEC = "allow-downgrade";
      DHCP = "ipv6";
      LinkLocalAddressing = "ipv6";
      # IPv6LinkLocalAddressGenerationMode = "eui64";
    };
    makeRoute = map (x: { routeConfig = x; });
  in {
    # "10-lo" = {
    #   name = "lo";
    #   address = [
    #     "127.0.0.1/8"
    #     "::1/128"
    #   ];
    # };
    "30-wan" = let
      gateway4 = "192.168.100.1";
      gateway6 = "fd19:5727:57f0:2:8dc:4ff:feea:3bdc";
    in {
      matchConfig.Name = "wan";
      networkConfig = networkConfig // {
        Description = "Incoming Internet network (WAN)";
      };
      ntp = [ gateway4 ] ++ config.networking.timeServers;
      address = [ "192.168.100.11/24" ];
      # vlan = [ "lan.1" ];
    };

    "30-lan" = {
      matchConfig.Name = "lan";
      networkConfig = networkConfig // {
        Description = "LAN network";
        Domains = [ "~lan" ];
      };
      ntp = config.networking.timeServers;
      address = [ "192.168.0.4/24" ];
      # vlan = [ "wan.42" ];
      routes = makeRoute [
        {
          # Destination = "0.0.0.0/0";
          Gateway = "192.168.0.1";
          GatewayOnLink = true;
        }
        {
          # Destination = "";
          Gateway = "";
          GatewayOnLink = true;
        }
      ];
    };
  };
}
