let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  src = fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
    sha256 = lock.nodes.flake-compat.locked.narHash;
  };
in
(import src { src = ./.; }).defaultNix
