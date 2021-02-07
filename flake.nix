{
  description = "Deployment for my OVH VPS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable-small";
  inputs.deploy-rs.url = "github:serokell/deploy-rs";
  # Secret management
  inputs.sops-nix.url = "github:Mic92/sops-nix";

  # Modules
  inputs.simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";

  outputs = inputs@{ self, nixpkgs, deploy-rs, ... }: let
    system = "x86_64-linux";
  in {
    nixosConfigurations.keanu = nixpkgs.lib.nixosSystem {
      inherit system;
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
          path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.keanu;
          user = "root";
        };
      };
    };

    devShell.x86_64-linux = let
      pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
      sops-nix = inputs.sops-nix.packages.${system};
      terraform = pkgs.terraform_0_14;
    in pkgs.mkShell {
      nativeBuildInputs = [ sops-nix.sops-pgp-hook ];

      sopsPGPKeyDirs = [
        "./secrets/keys/keanu.asc"
        "./secrets/keys/admin.asc"
      ];

      buildInputs = [
        deploy-rs.defaultPackage.${system}
        # (terraform.withPlugins (ps: with ps; [ ovh cloudflare ]))
        terraform
        sops-nix.ssh-to-pgp
      ];
    };
  };
}
