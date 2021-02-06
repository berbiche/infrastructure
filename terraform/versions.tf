terraform {
  required_version = ">= 0.13"

  required_providers {
    ovh = {
      source  = "ovh/ovh"
      # source  = "nixpkgs/ovh"
      version = ">= 0.10.0, < 1.0.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      # source  = "nixpkgs/cloudflare"
      version = "~> 2.0"
    }

    sops = {
      source = "carlpett/sops"
      version = "~> 0.5"
    }
  }
}
