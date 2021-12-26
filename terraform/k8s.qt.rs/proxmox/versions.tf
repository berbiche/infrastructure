terraform {
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.6"
    }

    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9.3"
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
