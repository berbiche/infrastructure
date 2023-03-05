{
  description = "My homelab's NixOS deployments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    colmena.url = "github:zhaofengli/colmena";
    flake-parts.url = "github:hercules-ci/flake-parts";
    mission-control.url = "github:Platonic-Systems/mission-control";
    # Secret management
    sops-nix.url = "github:Mic92/sops-nix";

    # Modules
    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-22.11";
    simple-nixos-mailserver.inputs = {
      nixpkgs.follows = "nixpkgs";
      nixpkgs-22_11.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }: let
    flakeConfig = toplevel@{inputs, self, withSystem, ...}: {
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ];

      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
        inputs.mission-control.flakeModule
      ];

      flake = {
        colmena = withSystem "x86_64-linux" ({pkgs, ...}: import ./nixos/colmena.nix {
          inherit inputs pkgs self;
          rootPath = ./nixos;
        });
      };

      perSystem = { config, final, self', inputs', pkgs, lib, system, ... }: let
        sops-nix = inputs'.sops-nix.packages;
        terraform = pkgs.terraform_1;
      in {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = builtins.attrValues toplevel.config.flake.overlays;
        };

        overlayAttrs = import ./nixos/overlay.nix {
          inherit final inputs;
          prev = pkgs;
        };

        # nix shell .#openshift-install
        packages = import ./packages.nix { inherit pkgs system; };

        # nix run .#terraform-fhs --
        # nix run .#bmc-access --
        # nix run .#openshift-install --
        apps = lib.mapAttrs (_: v: { type = "app"; program = v.exec; }) config.mission-control.scripts;
        mission-control.scripts = {
          bmc-access = {
            description = "Access iDrac Java BMC console";
            exec = toString (import ./scripts/bmc-access.nix { inherit pkgs; }).bmc;
          };
          terraform-fhs = {
            description = "Enter an FHS with Terraform dependencies";
            exec = let
              terraformFHS = import ./scripts/terraform-fhs.nix { inherit pkgs terraform; };
            in "${terraformFHS}/bin/${terraformFHS.meta.mainProgram}";
          };
          openshift-install = {
            description = "OpenShift installer script";
            exec = "${self'.packages.openshift-install}/bin/openshift-install";
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
            terraform
            sops-nix.ssh-to-pgp
            inputs'.colmena.packages.colmena

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

            self'.packages.openshift-install
            self'.packages.kubectl-slice
          ];

          shellHook = ''
            export KUBECONFIG=$PWD/kubeconfig
          '';
        };
      };
    };
  in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } flakeConfig;
}
