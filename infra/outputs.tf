output "talos_cp_01_vm_id" {
  value = proxmox_virtual_environment_vm.talos_cp_01.vm_id
}

# Current IPv4 addresses reported by the guest agent, loopback filtered out.
# In maintenance mode this is the temporary DHCP address used for the first
# talosctl apply-config --insecure. Refresh with: terraform apply -refresh-only
output "talos_cp_01_ipv4" {
  value = [
    for ip in flatten(proxmox_virtual_environment_vm.talos_cp_01.ipv4_addresses) : ip
    if ip != "127.0.0.1"
  ]
}
