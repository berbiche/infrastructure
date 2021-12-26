variable "host" {
  description = "Proxmox host to use"
  type        = string
}

variable "node_count" {
  description = "The amount of K8s node vms to spawn, including the master node."
  type        = number
  validation {
    condition     = var.node_count >= 0
    error_message = "The node count must be a positive number."
  }
}

variable "ssh_host" {
  description = "SSH host to access the Proxmox instance"
  type        = string
}

variable "ssh_user" {
  description = "SSH user to access the Proxmox instance"
  type        = string
}

variable "authorized_key_user" {
  type = string
  validation {
    condition     = var.authorized_key_user != ""
    error_message = "The specified user SSH public key does not exist."
  }
}

variable "authorized_key_admin" {
  type = string
  validation {
    condition     = var.authorized_key_admin != ""
    error_message = "The specified admin SSH public key does not exist."
  }
}

variable "ssh_private_key_path" {
  description = "Path to the SSH key used to connect to the host"
  type        = string
  validation {
    condition     = fileexists(var.ssh_private_key_path)
    error_message = "The specified SSH key does not exist."
  }
}

variable "thinpool" {
  description = "Proxmox thinpool to use for VMs"
  type        = string
}

variable "ipv4_addresses" {
  description = "IPv4 starting address to allocate VMs with CIDR"
  type        = list(string)
  # validation {
  #   condition     = length(var.ipv4_addresses) >= var.node_count
  #   error_message = "The number of IPv4 addresses must match the number of nodes plus one."
  # }
}

variable "ipv4_gateway" {
  description = "IPv4 gateway address without CIDR"
  type        = string
}

variable "nameservers" {
  description = "IP addresses of DNS nameservers"
  type        = list(string)
}

variable "secrets" {
  description = "SOPS-encrypted secrets for the Proxmox configuration"
  sensitive   = true
  type        = object({
    hashed_password = string
  })
}

variable "memory" {
  description = "Amount of memory on nodes, in MiB"
  type        = number
  default     = 20480
}

variable "cores" {
  description = "Amount of physical cores to assign to each node"
  type        = number
  default     = 6
}
