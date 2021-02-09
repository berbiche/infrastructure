let
  lock = builtins.getFlake (toString ./.);
  src = lock.inputs.flake-compat.outPath;
in
(import src { src = ./.; }).defaultNix
