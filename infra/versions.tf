terraform {
  required_version = ">= 1.17.0"

  # State lives in HCP Terraform (encrypted at rest, versioned). Execution mode
  # is Local: plans run on this machine, which can reach Proxmox on the LAN.
  cloud {
    organization = "vicLab"
    workspaces {
      name = "proxmox"
    }
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.118.0"
    }
  }
}
