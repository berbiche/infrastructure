{
  description = "My homelab's NixOS deployments";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable-small";
  inputs.deploy-rs.url = "github:serokell/deploy-rs";
  inputs.colmena.url = "github:zhaofengli/colmena";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  # Secret management
  inputs.sops-nix.url = "github:Mic92/sops-nix";

  # Modules
  inputs.simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-22.11";
  inputs.simple-nixos-mailserver.inputs = {
    nixpkgs.follows = "nixpkgs";
    nixpkgs-22_11.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, deploy-rs, ... }: let
    supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];

    nodesConfigurations = import ./nixos/hosts/deployments.nix {
      inherit inputs;
      rootPath = ./nixos;
    };

    colmenaNodeConfigurations = import ./nixos/colmena.nix {
      inherit inputs;
      inherit self;
      rootPath = ./nixos;
    };
  in {
    overlays.packages = import ./nixos/pkgs;
    overlays.inputs = final: prev: { inherit inputs; };

    inherit (nodesConfigurations) deploy;

    colmena = colmenaNodeConfigurations;

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  }
  // inputs.flake-utils.lib.eachSystem supportedSystems (system: let
    pkgs = import inputs.nixpkgs-unstable {
      inherit system;
      overlays = builtins.attrValues self.overlays;
    };
    sops-nix = inputs.sops-nix.packages.${system};
    terraform = pkgs.terraform_1;

  in {
    # nix shell .#openshift-install
    packages = import ./packages.nix { inherit inputs pkgs system; };

    # nix run .#terraform-fhs --
    # nix run .#bmc-access --
    # nix run .#openshift-install --
    apps = {
      bmc-access = {
        type = "app";
        program = toString (import ./scripts/bmc-access.nix { inherit nixpkgs; }).bmc;
      };
      terraform-fhs = {
        type = "app";
        program = let
          terraformFHS = import ./scripts/terraform-fhs.nix { inherit pkgs terraform; };
        in "${terraformFHS}/bin/${terraformFHS.meta.mainProgram}";
      };
      openshift-install = {
        type = "app";
        program = "${self.packages.${system}.openshift-install}/bin/openshift-install";
      };
    };

    devShells.default = pkgs.mkShell {
      name = "dev";

      nativeBuildInputs = [
        sops-nix.sops-import-keys-hook
      ];

      KUSTOMIZE_PLUGIN_HOME = pkgs.buildEnv {
        name = "kustomize-plugins";
        paths =  [ pkgs.kustomize-sops ];
        postBuild = ''
          mv $out/lib/* $out
          rm -r $out/lib
        '';
        pathsToLink = [ "/lib" ];
      };

      buildInputs = [
        deploy-rs.defaultPackage.${system}
        terraform
        sops-nix.ssh-to-pgp
        inputs.colmena.packages.${system}.colmena

        pkgs.ansible_2_13
        pkgs.jsonnet
        pkgs.jsonnet-bundler
        pkgs.kubectl
        pkgs.kubectx
        pkgs.kubernetes-helm
        pkgs.kubetail
        # pkgs.kustomize_3
        pkgs.kustomize
        # pkgs.ltrace
        pkgs.pipenv
        pkgs.python311
        pkgs.sops
        pkgs.openshift

        self.packages.${system}.openshift-install
        self.packages.${system}.kubectl-slice
      ];

      shellHook = ''
        export KUBECONFIG=$PWD/kubeconfig
      '';
    };
  });
}
