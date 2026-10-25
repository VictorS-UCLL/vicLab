variable "proxmox_endpoint" {
  description = "Proxmox VE API URL"
  type        = string
  default     = "https://192.168.0.50:8006/"
}

variable "proxmox_node" {
  description = "Proxmox node name (hostname of the hypervisor)"
  type        = string
  default     = "pve"
}

variable "talos_version" {
  description = "Talos release. Must match talosctl in mise.toml."
  type        = string
  default     = "v1.14.4"
}

variable "talos_schematic_id" {
  description = "Image Factory ID of talos/image/schematic.yaml"
  type        = string
  default     = "ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515"
}

variable "cp_cores" {
  description = "vCPUs for the control-plane node"
  type        = number
  default     = 4
}

variable "cp_memory_mb" {
  description = "RAM for the control-plane node. 6 GB while the v1 VM still runs; raise after cutover."
  type        = number
  default     = 6144
}

variable "cp_disk_gb" {
  description = "System disk size (thin-provisioned)"
  type        = number
  default     = 80
}

variable "cp_mac_address" {
  description = "Fixed MAC so a DHCP reservation can target this VM"
  type        = string
  default     = "BC:24:11:7A:10:01"
}
