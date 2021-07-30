{
  description = "Deployment for my OVH VPS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable-small";
  inputs.nixpkgs-kustomize-3.url = "github:NixOS/nixpkgs/f294808d544abb5ef701738887138ea8ed9a9dd3";
  inputs.deploy-rs.url = "github:serokell/deploy-rs";
  inputs.flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
  # Secret management
  inputs.sops-nix.url = "github:Mic92/sops-nix";

  # Modules
  inputs.simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";

  outputs = inputs@{ self, nixpkgs, deploy-rs, ... }: let
    system = "x86_64-linux";

    pkgs = import inputs.nixpkgs-unstable {
      inherit system;
      overlays = builtins.attrValues self.overlays;
    };
    sops-nix = inputs.sops-nix.packages.${system};
    terraform = pkgs.terraform_0_14;

    nodesConfigurations = import ./nixos/hosts/deployments.nix {
      inherit inputs system;
      rootPath = ./nixos;
    };

    # FHS for the terraform-provider-b2
    # because writing a derivation is complex (it embeds a python binary generated with pyinstaller)
    terraformFHS = pkgs.buildFHSUserEnv {
      name = "terraform-keanu-fhs";
      targetPkgs = pkgs: [
        pkgs.sops
        terraform
        pkgs.zlib
      ];
      # Only one line can be in the runScript option
      runScript = ''
        sops exec-env secrets/terraform-backend.yaml ${pkgs.writeShellScript "fhs-terraform-sops" ''
          export PS1="\e[0;32m(keanu-shell)\e[m \e[0;34m\w\e[m \e[0;31m$\e[m "
          export name="terraform"
          exec zsh
        ''}
      '';
    } // {
      meta.mainProgram = terraformFHS.name;
    };

  in nodesConfigurations // {

    # nix run .#terraform-fhs
    # nix run .#bmc-access
    apps.${system} = {
      bmc-access = {
        type = "app";
        program = toString (import ./scripts/bmc-access.nix { inherit nixpkgs; }).bmc;
      };
      terraform-fhs = {
        type = "app";
        program = "${terraformFHS}/bin/${terraformFHS.name}";
      };
    };

    overlays.packages = import ./nixos/pkgs;
    overlays.inputs = final: prev: { inherit inputs; };
    overlays.kustomize-3 = final: prev: {
      kustomize = inputs.nixpkgs-kustomize-3.legacyPackages.${system}.kustomize;
    };

    devShell.${system} = pkgs.mkShell {
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
        pkgs.sops
        pkgs.python38
        pkgs.ansible_2_9
        pkgs.pipenv
        pkgs.kubectl
        pkgs.kubetail
        pkgs.kubectx
        pkgs.kustomize
        pkgs.kubernetes-helm
        pkgs.jsonnet
        pkgs.jsonnet-bundler
      ];

      SFPATH =
        (pkgs.runCommandLocal "zsh-kubectl-completions" { buildInputs = [ pkgs.kubectl ]; } ''
          mkdir -p $out/share/zsh/site-functions/ $out/share/bash-completions/completions
          kubectl completion zsh > $out/share/zsh/site-functions/_kubectl
          kubectl completion bash > $out/share/bash-completions/completions/kubectl
          chmod +x $out/share/zsh/site-functions/_kubectl $out/share/bash-completions/completions/kubectl
        '');

      shellHook = ''
        export KUBECONFIG=$PWD/kubespray/inventory/artifacts/admin.conf
        # export XDG_DATA_DIRS="''${XDG_DATA_DIRS-}''${XDG_DATA_DIRS+:}$SFPATH/share/bash-completions/completions"
        # . ${pkgs.bash-completion}/etc/profile.d/bash_completion.sh
        # if [ -n "''${ZSH_VERSION:-}" ]; then
        #   export fpath=($fpath $SFPATH/share/zsh/site-functions)
        # fi
      '';
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
