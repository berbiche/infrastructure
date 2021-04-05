{ config, inputs, lib, ... }:

let
  globalCfg = config.configurations.global;
in
{
  users.users.admin.extraGroups = [
    (lib.optionalString config.security.doas.enable "doas")
    (lib.optionalString config.security.sudo.enable "wheel")
  ];

  security.apparmor.enable = false;
  # security.hideProcessInformation = true;

  ###### Disabled deploy user because I also need to allow `rm`ing lock files and canary
  ###### files and these files have a dynamic path in /tmp/
  ###### so the sudo security rules doesn't work
  ## Deployment host
  # users.users.deploy = {
  #   isSystemUser = true;
  #   # The user cannot login by default unless a shell is set
  #   # shell = pkgs.shadow;
  #   openssh.authorizedKeys.keys = globalCfg.authorizedKeys;
  # };

  # security.sudo = {
  #   enable = true;
  #   extraRules = [{
  #     users = [ config.users.users.deploy.name ];
  #     runAs = "root";
  #     commands = map (v: { command = v; options = [ "NOPASSWD" ]; }) [
  #       "/nix/var/nix/profiles/system/deploys-rs-activate"
  #       "/nix/var/nix/profiles/system/activate-rs"
  #     ];
  #   }];
  # };

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
