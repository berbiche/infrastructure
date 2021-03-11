{ config, inputs, pkgs, ... }:

{
  imports = [
    ./networking.nix
    ./security.nix
    ./prometheus-node-exporter.nix
  ];

  sops.secrets.admin-pass = { };

  networking.firewall.allowPing = true;

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    ports = [ 59910 ];
    listenAddresses = [
      { addr = "[::0]"; port = 59910; }
      { addr = "0.0.0.0"; port = 59910; }
    ];
  };

  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7OSbLUwgRy5NY0VWDmyHUIUh1gAR/EYCm3Z4Y6C0iu keanu.ovh"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjVrgNOlB82cM5xUF2Z/WasfSRhmWc/1tjiUqqUfmYW OVH Cloud"
  ];
  users.users.admin = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.bashInteractive;
    hashedPassword = "$6$DUzWCM9C$cxkLY2c1efB/Bxn/jzh7Y4HBPkxRmcHdrPoxsl.0f2/rg/H6AZrsj8c7PvvE.Wj1YbTWsKdDjWosVOxnZ6Bgb.";
    # Will not work until initrd supports secrets
    # passwordFile = config.sops.secrets.admin-pass.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7OSbLUwgRy5NY0VWDmyHUIUh1gAR/EYCm3Z4Y6C0iu keanu.ovh"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjVrgNOlB82cM5xUF2Z/WasfSRhmWc/1tjiUqqUfmYW OVH Cloud"
    ];
  };

  environment.noXlibs = true;

  environment.systemPackages = with pkgs; [
    vim
    mtr
    bind # nslookup dig
    screen # for the bmc server
  ];
}
