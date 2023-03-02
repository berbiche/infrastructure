{ inputs, pkgs, self, rootPath }:

let
in
{
  meta = {
    nixpkgs = pkgs;
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
      ./configurations
    ];

    system.stateVersion = "22.11";

    deployment.replaceUnknownProfiles = true;
  };

  morpheus = { name, nodes, ... }: {
    imports = [ ./hosts/morpheus ];
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

    system.stateVersion = "22.11";

    networking.hostName = "keanu";
    networking.domain = "normie.dev";
  };

  builder = { name, nodes, ... }: {
    imports = [ ./hosts/builder ];
    deployment.targetHost = "nixos-builder.node.tq.rs";
    deployment.targetUser = "nicolas";

    system.stateVersion = "22.11";

    networking.hostName = "nixos-builder";
    networking.domain = "node.tq.rs";
  };
}
