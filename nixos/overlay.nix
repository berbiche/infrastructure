{ final, inputs, prev }:
let
  unstable = import inputs.nixpkgs-unstable {
    inherit (prev) system;
    config.allowUnfree = true;
  };
  pkgsPlex = import inputs.nixpkgs-pr216547 {
    inherit (prev) system;
    config.allowUnfree = true;
  };
in
{
  # Traefik's WebUI is broken on 20.09
  packages.traefik = unstable.traefik;

  # Use the latest versions for these
  packages.jackett = unstable.jackett;
  packages.plex = pkgsPlex.plex;
  packages.radarr = unstable.radarr;
  packages.sonarr = unstable.sonarr;
  packages.qbittorrent = unstable.qbittorrent;
}
