variable "host" {
  description = "Proxmox host to use"
  type        = string
}

variable "node_count" {
  description = "The amount of K8s node vms to spawn, excluding the master node so N nodes + 1 for the master."
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
  default     = "root"
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
