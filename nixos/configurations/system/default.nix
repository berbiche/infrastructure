{ config, inputs, pkgs, modulesPath, rootPath, ... }:

let
  globalCfg = config.configurations.global;
in
{
  imports = [
    ./networking.nix
    ./security.nix
    ./prometheus-node-exporter.nix
    (modulesPath + "/profiles/minimal.nix")
  ];

  boot.kernelParams = [ "panic=1" "boot.panic_on_fail" ];

  sops.defaultSopsFile = rootPath + "/secrets/keanu.yaml";

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
  users.users.root.openssh.authorizedKeys.keys = globalCfg.authorizedKeys;
  users.users.admin = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.bashInteractive;
    hashedPassword = "$6$DUzWCM9C$cxkLY2c1efB/Bxn/jzh7Y4HBPkxRmcHdrPoxsl.0f2/rg/H6AZrsj8c7PvvE.Wj1YbTWsKdDjWosVOxnZ6Bgb.";
    # Will not work until initrd supports secrets
    # passwordFile = config.sops.secrets.admin-pass.path;
    openssh.authorizedKeys.keys = globalCfg.authorizedKeys;
  };

  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    vim
    mtr
    bind # nslookup dig
    screen # for the bmc server
  ];
}
