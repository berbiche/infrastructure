# My OVH VPS configuration

In this repository resides the configuration for my OVH VPS host.

Technologies used:

- [NixOS](https://nixos.org) for the declarative OS and service configuration
- [deploy-rs](https://github.com/serokel/deploy-rs) to deploy my NixOS configuration
- [Terraform](https://terraform.io) for the automated DNS and OVH configuration
- [Backblaze](https://www.backblaze.com) for the cheap object storage

## Terraform

The terraform state is currently manually synced between my computers
until I setup a backblaze storage for it.

Terraform needs to be run from the FHS provided in the flake default package
because the Backblaze B2 provider extracts a binary embedded in its binary
and the paths needs to be `patchelf`d.

`nix-shell` will spawn you in the FHS with the required packages for the
Terraform B2 plugin to work.

## Backblaze

Documentation about capabilities:
<https://www.backblaze.com/b2/docs/application_keys.html>

Retention settings for the dovecot email bucket: 30 days

## NixOS

### Modules

I host different services on my NixOS server.
