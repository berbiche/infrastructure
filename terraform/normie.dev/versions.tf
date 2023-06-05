terraform {
  required_version = ">= 0.14"

  backend "s3" {
    bucket = "normie-dev-terraform"
    key    = "normie-dev/normie-dev-email.tfstate"
    # Literally doesn't matter with Backblaze B2
    region = "us-west-1"
    # Region doesn't matter with B2
    skip_region_validation = true
    # Do not use the STS API (S3-only)
    skip_credentials_validation = true
  }

  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.8.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.7.0"
    }

    ovh = {
      source  = "ovh/ovh"
      version = ">= 0.15.0, < 1.0.0"
    }

    sops = {
      source  = "carlpett/sops"
      version = "~> 0.7.0"
    }
  }
}
