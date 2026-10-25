# Talos ISO, downloaded by Proxmox itself straight from the Image Factory.
resource "proxmox_download_file" "talos_iso" {
  node_name    = var.proxmox_node
  datastore_id = "local"
  content_type = "iso"
  url          = "https://factory.talos.dev/image/${var.talos_schematic_id}/${var.talos_version}/metal-amd64.iso"
  file_name    = "talos-${var.talos_version}-${substr(var.talos_schematic_id, 0, 8)}-amd64.iso"
}

resource "proxmox_virtual_environment_vm" "talos_cp_01" {
  name            = "talos-cp-01"
  description     = "Talos control-plane node. Managed by Terraform (vicLab/infra): do not edit in the UI."
  tags            = ["kubernetes", "talos", "terraform"]
  node_name       = var.proxmox_node
  vm_id           = 200
  on_boot         = true
  machine         = "q35"
  scsi_hardware   = "virtio-scsi-single"
  stop_on_destroy = true

  agent {
    enabled = true
    timeout = "5m"
  }

  cpu {
    cores = var.cp_cores
    type  = "host"
  }

  memory {
    dedicated = var.cp_memory_mb
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = var.cp_disk_gb
    file_format  = "raw"
    discard      = "on"
    iothread     = true
    ssd          = true
  }

  # First boot: the disk is empty, so the BIOS falls through to the ISO
  # (maintenance mode). After talosctl installs to disk, the VM boots from scsi0.
  cdrom {
    file_id   = proxmox_download_file.talos_iso.id
    interface = "ide2"
  }
  boot_order = ["scsi0", "ide2"]

  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = var.cp_mac_address
  }

  operating_system {
    type = "l26"
  }

  # Serial console: the xterm.js console in Proxmox supports copy-paste.
  serial_device {}
}
