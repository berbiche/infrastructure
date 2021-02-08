terraform {
  required_version = ">= 0.13"

  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = ">= 0.10.0, < 1.0.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 2.0"
    }

    sops = {
      source  = "carlpett/sops"
      version = "~> 0.5"
    }

    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.2"
    }
  }
}
