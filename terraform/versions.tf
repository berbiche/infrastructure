terraform {
  required_version = ">= 0.14"

  backend "s3" {
    bucket = "normie-dev-terraform"
    key = "normie-dev/terraform.tfstate"
    # Literally doesn't matter with Backblaze B2
    region = "us-west-1"
    # Region doesn't matter with B2
    skip_region_validation = true
    # Do not use the STS API (S3-only)
    skip_credentials_validation = true
  }

  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = ">= 0.10.0, < 1.0.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 2.0, != 2.18"
    }

    sops = {
      source  = "carlpett/sops"
      version = "~> 0.5"
    }

    b2 = {
      source  = "Backblaze/b2"
      version = "0.2.1"
    }

    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.6.0"
    }

    macaddress = {
      source = "ivoronin/macaddress"
      version = "0.2.2"
    }

    random = {
      source = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
}
