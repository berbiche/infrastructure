{ inputs, self, rootPath }:

let
in
{
  meta = {
    nixpkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    specialArgs = {
      inherit inputs;
    };
  };

  defaults = { ... }: {
    _module.args = {
      inherit self;
      inherit rootPath;
    };

    imports = [
      inputs.sops-nix.nixosModule
    ] ++ import ./configurations;

    system.stateVersion = "22.11";

    deployment.replaceUnknownProfiles = true;
  };

  morpheus = { name, nodes, ... }: {
    imports = [ ./hosts/morpheus ];
    # deployment.targetHost = "morpheus.node.tq.rs";
    deployment.targetHost = "morpheus.node.tq.rs";
    deployment.targetUser = "admin";
    networking.hostName = "morpheus";
    networking.domain = "node.tq.rs";
  };

  keanu = { name, nodes, ... }: {
    imports = [ ./hosts/keanu ];
    deployment.targetHost = "keanu.ovh";
    deployment.targetUser = "root";
    deployment.targetPort = 59910;

    networking.hostName = "keanu";
    networking.domain = "ovh";
  };
}
