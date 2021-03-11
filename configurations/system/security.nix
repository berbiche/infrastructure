{ config, inputs, rootPath, lib, ... }:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops.defaultSopsFile = rootPath + "/secrets/keanu.yaml";

  users.users.admin.extraGroups = [
    (lib.optionalString config.security.doas.enable "doas")
    (lib.optionalString config.security.sudo.enable "wheel")
  ];

  security.apparmor.enable = false;
  # security.hideProcessInformation = true;

  # Deployment host
  users.users.deploy = {
    isSystemUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO7OSbLUwgRy5NY0VWDmyHUIUh1gAR/EYCm3Z4Y6C0iu keanu.ovh"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjVrgNOlB82cM5xUF2Z/WasfSRhmWc/1tjiUqqUfmYW OVH Cloud"
    ];
  };

  security.sudo = {
    enable = true;
    extraRules = [{
      users = [ config.users.users.deploy.name ];
      runAs = "root";
      commands = map (v: { command = v; options = [ "NOPASSWD" ]; }) [
        "/nix/var/nix/profiles/system/deploys-rs-activate"
        "/nix/var/nix/profiles/system/activate-rs"
      ];
    }];
  };

  # security.doas = {
  #   enable = false;
  #   extraRules = [
  #     {
  #       groups = [ config.users.groups.doas.name ];
  #       noPass = false;
  #       keepEnv = true;
  #     }
  #     {
  #       users = [ config.users.users.deploy.name ];
  #       cmd = "/nix/var/nix/profiles/system/deploys-rs-activate";
  #       noPass = true;
  #       runAs = "root";
  #     }
  #   ];
  # };
}
