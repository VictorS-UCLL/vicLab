# homelab

Single-node Talos Kubernetes on Proxmox VE, rebuilt from git.

> **Status:** v2 rebuild in progress. v1 (K3s on Ubuntu, hand-configured) is retired.

## Principle

Everything needed to rebuild this lab from zero lives in this repository,
plus one age private key kept in a password manager. Nothing is configured
by hand unless it is committed here the same day.

## Layout

| Path | Contents | Applied by |
|---|---|---|
| `infra/` | Proxmox VMs (OpenTofu) | me — `tofu apply` |
| `talos/` | Talos machine config | me — `talosctl apply-config` |
| `ansible/` | Proxmox host baseline | me — `ansible-playbook` |
| `kubernetes/bootstrap/` | Argo CD + root application | me, once |
| `kubernetes/platform/` | Traefik, cloudflared, monitoring | Argo CD |
| `kubernetes/apps/` | Workloads | Argo CD |
| `docs/adr/` | Architecture decisions and why | — |
| `docs/runbooks/` | Rebuild and recovery procedures | — |

Only the Kubernetes layer is GitOps in the strict sense (pulled and continuously
reconciled by Argo CD). The layers below it are push-based infrastructure as code.

## Tooling

CLI versions are pinned in `mise.toml`. On a fresh machine: `mise install`.
