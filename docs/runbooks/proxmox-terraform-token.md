# Proxmox API token for Terraform

Terraform authenticates to Proxmox as a dedicated user with a minimal role,
never as root. Run on the Proxmox host (PVE 9.x):

```bash
pveum role add Terraform -privs "VM.Allocate VM.Audit VM.PowerMgmt VM.Config.CDROM VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.GuestAgent.Audit Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit SDN.Use Sys.Audit Sys.AccessNetwork"
pveum user add terraform@pve --comment "Terraform provider (vicLab repo)"
pveum aclmod / -user terraform@pve -role Terraform
pveum user token add terraform@pve vicLab --privsep 0
```

- No password on `terraform@pve`: it cannot log in to the UI, only use the token.
- PVE 9 removed `VM.Monitor`; monitor access now falls under `Sys.Audit`.
- `Datastore.AllocateTemplate` + `Sys.AccessNetwork`: lets Terraform download the Talos ISO.
- Privileges are added only when a real 403 proves they are needed.
- The token secret lives in the password manager. Terraform reads it from the
  `PROXMOX_VE_API_TOKEN` environment variable; it is never written to a file in this repo.

Rotate: `pveum user token remove terraform@pve vicLab`, then re-run the last command.
