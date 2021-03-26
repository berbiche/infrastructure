{
  description = "Deployment for my OVH VPS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable-small";
  inputs.deploy-rs.url = "github:serokell/deploy-rs";
  inputs.flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
  # Secret management
  inputs.sops-nix.url = "github:Mic92/sops-nix";

  # Modules
  inputs.simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";

  outputs = inputs@{ self, nixpkgs, deploy-rs, ... }: let
    system = "x86_64-linux";
    pkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    sops-nix = inputs.sops-nix.packages.${system};
    terraform = pkgs.terraform_0_14;

    nodesConfigurations = import ./hosts/deployments.nix {
      inherit inputs system;
    };

  in nodesConfigurations // {

    packages = import ./bmc-access.nix { inherit nixpkgs; };

    overlays.packages = import ./pkgs;
    overlays.inputs = final: prev: { inherit inputs; };

    # FHS for the terraform-provider-b2
    # because writing a derivation is complex (it embeds a python binary generated with pyinstaller)
    defaultPackage.${system} =
      (pkgs.buildFHSUserEnv {
        name = "fhs-1";
        targetPkgs = pkgs: [
          pkgs.sops
          terraform
          pkgs.zlib
        ];
        # Only one line can be in the runScript option
        runScript = ''
          sops exec-env secrets/terraform-backend.yaml bash
        '';
      }).env;

    devShell.x86_64-linux = pkgs.mkShell {
      nativeBuildInputs = [
        sops-nix.sops-pgp-hook
        # (pkgs.makeSetupHook {
        #   name = "sops-terraform-hook";
        #   substitutions.sops = "${pkgs.sops}/bin/sops";
        #   deps = [ pkgs.sops pkgs.gnupg ];
        # } (pkgs.writeShellScript "sops-terraform-hook" ''
        #   echo "Plug-in and touch the YubiKey"
        #   eval "$(@sops@ --decrypt --output-type dotenv secrets/terraform-backend.yaml)"
        # ''))
      ];

      sopsPGPKeyDirs = [
        "./secrets/keys"
      ];

      buildInputs = [
        deploy-rs.defaultPackage.${system}
        terraform
        sops-nix.ssh-to-pgp
        pkgs.sops
      ];
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
