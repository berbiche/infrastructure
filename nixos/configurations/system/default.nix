{ config, lib, pkgs, inputs, modulesPath, rootPath, ... }:

let
  globalCfg = config.configurations.global;
in
{
  imports = [
    ./networking.nix
    ./prometheus-node-exporter.nix
    (modulesPath + "/profiles/minimal.nix")
  ];

  boot.kernelParams = [ "panic=1" "boot.panic_on_fail" ];

  sops.defaultSopsFile = lib.mkDefault (rootPath + "/secrets/keanu.yaml");

  sops.secrets.admin-pass = { };

  networking.firewall.allowPing = true;

  services.openssh = {
    enable = true;
    openFirewall = true;
    passwordAuthentication = false;
    permitRootLogin = "no";
  };

  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys = globalCfg.authorizedKeys;
  users.users.admin = {
    isNormalUser = true;
    shell = pkgs.bashInteractive;
    extraGroups = [ "wheel" ];
    hashedPassword = "$6$DUzWCM9C$cxkLY2c1efB/Bxn/jzh7Y4HBPkxRmcHdrPoxsl.0f2/rg/H6AZrsj8c7PvvE.Wj1YbTWsKdDjWosVOxnZ6Bgb.";
    # Will not work until initrd supports secrets
    # passwordFile = config.sops.secrets.admin-pass.path;
    openssh.authorizedKeys.keys = globalCfg.authorizedKeys;
  };
  security.sudo.wheelNeedsPassword = false;

  time.timeZone = lib.mkDefault "America/Toronto";
  i18n.defaultLocale = "en_US.UTF-8";

  programs.mtr.enable = true;
  environment.systemPackages = with pkgs; [
    vim
    bind # nslookup dig
    tmux
    iotop iperf tcpdump htop netcat-gnu
  ];

  nix.gc = {
    automatic = true;
    dates = "monthly";
    options = "--delete-older-than 30d";
  };
}
