{
  description = "Deployment for my OVH VPS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.deploy-rs.url = "github:serokell/deploy-rs";

  outputs = inputs@{ self, nixpkgs, deploy-rs }: {
    nixosConfigurations.keanu = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./profiles/system/configuration.nix ];
      specialArgs = { inherit self inputs; };
    };

    deploy.nodes.keanu = {
      sshOpts = [ "-p" "59910" ];
      hostname = "keanu.ovh";
      fastConnection = false;
      profiles = {
        system = {
          sshUser = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.keanu;
          user = "root";
        };
      };
    };

    devShell.x86_64-linux = let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in pkgs.mkShell {
      buildInputs = [ deploy-rs.defaultPackage.x86_64-linux ];
    };
  };
}
