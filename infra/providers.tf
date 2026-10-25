provider "proxmox" {
  endpoint = var.proxmox_endpoint

  # Proxmox serves a self-signed certificate. Known debt: replace it with an
  # ACME certificate, then delete this line.
  insecure = true

  # Credentials: PROXMOX_VE_API_TOKEN environment variable only. Never in a file.
}
