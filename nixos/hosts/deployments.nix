{ inputs, system, rootPath }:

let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;

  activateNixos = inputs.deploy-rs.lib.${system}.activate.nixos;

  makeHost = host: lib.nixosSystem {
    inherit system;
    modules = [
      inputs.sops-nix.nixosModule
      (./. + "/${host}")
    ] ++ lib.concatLists [
      (import ../configurations)
      (import ../modules)
    ];
    specialArgs = {
      inherit (inputs) self;
      inherit inputs rootPath;
    };
    pkgs = import nixpkgs {
      inherit system;
      overlays = builtins.attrValues inputs.self.overlays;
      config.allowUnfree = true;
    };
  };
in
rec {
  nixosConfigurations = lib.flip lib.genAttrs makeHost [
    "apoc"
    "keanu"
    "mouse"
    "switch"
  ];

  deploy.nodes = let
    makeNode = x: {
      sshOpts = [ "-p" "59910" ];
      hostname = "proxmox-${x}";
      fastConnection = false;
      profilesOrder = [ "system" ];
      profiles.system = {
        sshUser = "root";
        user = "root";
        path = activateNixos nixosConfigurations.${x};
      };
    };
    generatedNodes = lib.flip lib.genAttrs makeNode [
      "apoc"
      "keanu"
      "mouse"
      # "switch"
    ];
  in
    lib.recursiveUpdate generatedNodes {
      apoc.profiles.system.autoRollback = false;
      apoc.profiles.system.magicRollback = false;

      keanu.hostname = "keanu.ovh";
    };
}
