{ pkgs, lib, ... }:

let
  inherit (lib) mkDefault;
in
{
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [ "213.186.33.99" "8.8.8.8" ];
    timeServers = [
      "ntp.ovh.net"
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];
    defaultGateway = "51.222.12.1";
    defaultGateway6 = "2607:5300:205:200::1";
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    resolvconf.dnsExtensionMechanism = false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address="51.222.15.167"; prefixLength=32; }
        ];
        ipv6.addresses = [
          { address="fe80::f816:3eff:feb6:863d"; prefixLength=64; }
          { address="2607:5300:205:200::404"; prefixLength=128; }
        ];
        ipv4.routes = [ { address = "51.222.12.1"; prefixLength = 32; } ];
        ipv6.routes = [ { address = "2607:5300:205:200::1"; prefixLength = 128; } ];
      };

    };
  };
  # Rename device to eth0
  services.udev.extraRules = ''
    ATTR{address}=="fa:16:3e:b6:86:3d", NAME="eth0"
  '';

  services.resolved.enable = true;
  services.resolved.dnssec = "allow-downgrade";

  # Enable strict reverse path filtering (that is, do not attempt to route
  # packets that "obviously" do not belong to the iface's network; dropped
  # packets are logged as martians).
  boot.kernel.sysctl."net.ipv4.conf.all.log_martians" = mkDefault true;
  boot.kernel.sysctl."net.ipv4.conf.all.rp_filter" = mkDefault "1";
  boot.kernel.sysctl."net.ipv4.conf.default.log_martians" = mkDefault true;
  boot.kernel.sysctl."net.ipv4.conf.default.rp_filter" = mkDefault "1";

  # Ignore broadcast ICMP (mitigate SMURF)
  boot.kernel.sysctl."net.ipv4.icmp_echo_ignore_broadcasts" = mkDefault true;

  # Ignore incoming ICMP redirects (note: default is needed to ensure that the
  # setting is applied to interfaces added after the sysctls are set)
  boot.kernel.sysctl."net.ipv4.conf.all.accept_redirects" = mkDefault false;
  boot.kernel.sysctl."net.ipv4.conf.all.secure_redirects" = mkDefault false;
  boot.kernel.sysctl."net.ipv4.conf.default.accept_redirects" = mkDefault false;
  boot.kernel.sysctl."net.ipv4.conf.default.secure_redirects" = mkDefault false;
  boot.kernel.sysctl."net.ipv6.conf.all.accept_redirects" = mkDefault false;
  boot.kernel.sysctl."net.ipv6.conf.default.accept_redirects" = mkDefault false;

  # Ignore outgoing ICMP redirects (this is ipv4 only)
  boot.kernel.sysctl."net.ipv4.conf.all.send_redirects" = mkDefault false;
  boot.kernel.sysctl."net.ipv4.conf.default.send_redirects" = mkDefault false;
}
