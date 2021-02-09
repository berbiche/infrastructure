# My OVH VPS configuration

In this repository resides the configuration for my OVH VPS host.

Technologies used:

- [NixOS](https://nixos.org) for the declarative OS and service configuration
- [deploy-rs](https://github.com/serokel/deploy-rs) to deploy my NixOS configuration
- [Terraform](https://terraform.io) for the automated DNS and OVH configuration
- [Backblaze](https://www.backblaze.com) for the cheap object storage

## Initial configuration

### Configuring the VPS

- Create a VPS at `$HOSTING_PROVIDER`
- `nixos-infect` the VPS

### Configuring Terraform

Enter the shell with `nix-shell` to get access to all the required variables
and to be able to use the `terraform-provider-b2`.

- Get an API token from OVH and update `secrets/ovh.yaml`
- Get an API token from Cloudflare and update `secrets/cloudflare.yaml`
- Get an API token from Backblaze and update `secrets/backblaze.yaml`
- Create a Backblaze bucket and application key for that bucket for the
  Terraform state and update `secrets/terraform-backend.yaml`

All required secrets are public in the appropriate SOPS file in `secrets/`
(but not their values).

- `terraform init terraform/`

## SOPS Cheatsheet

``` console
$ sops -i secrets/cloudflare.yaml
edit stuff in $EDITOR
:wq

File is encrypted inline
```

``` console
$ sops exec-env secrets/some-file bash
bash-4.4$
```

## Deployment

Using deploy-rs, `deploy --`

## Terraform

The Terraform state is managed outside of the repository in a B2 bucket.

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
