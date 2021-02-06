# My OVH VPS configuration

In this repository resides the configuration for my OVH VPS host.

Technologies used:

- [NixOS](https://nixos.org) for the declarative OS and service configuration
- [deploy-rs](https://github.com/serokel/deploy-rs) to deploy my NixOS configuration
- [Terraform](https://terraform.io) for the automated DNS and OVH configuration

## Terraform

The terraform state is currently manually synced between my computers
until I setup a backblaze storage for it.

## NixOS

### Modules

I host different services on my NixOS server.
