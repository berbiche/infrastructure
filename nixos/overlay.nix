{ final, inputs, prev }:
let
  importPkgs = x: import x {
    inherit (prev) system;
    config.allowUnfree = true;
  };

  unstable = importPkgs inputs.nixpkgs-unstable;
  # pkgsPlex = importPkgs inputs.nixpkgs-plex;
  # pkgsCockpit = importPkgs inputs.nixpkgs-cockpit;
in
{
  # Traefik's WebUI is broken on 20.09
  packages.traefik = unstable.traefik;

  # Use the latest versions for these
  packages.jackett = unstable.jackett;
  packages.plex = unstable.plex;
  packages.radarr = unstable.radarr;
  packages.sonarr = unstable.sonarr;
  packages.qbittorrent = unstable.qbittorrent;

  # Not merged in 22.11
  packages.cockpit = unstable.cockpit;
}
