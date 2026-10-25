# vicLab

Single-node Talos Kubernetes on Proxmox VE, rebuilt from git.

> **Status:** v2 rebuild in progress (see [Status](#status)). v1 (K3s on a
> hand-configured Ubuntu VM) keeps serving vic420.com until cutover.

## Principle

Everything needed to rebuild this lab from zero lives in this repository,
plus one age private key kept in a password manager. Nothing is configured
by hand unless it is committed here the same day. If it is not in git, it
does not exist.

## Architecture

```
Proxmox VE 9 — HP Pavilion laptop (i7-9750H, 16 GB)
└── VM 200  talos-cp-01  Talos Linux, single-node Kubernetes (control plane + workloads)
    ├── Argo CD                pulls kubernetes/ from this repo       (planned)
    ├── Traefik                ingress                                 (planned)
    ├── cloudflared            Cloudflare Tunnel, no inbound ports     (planned)
    └── kube-prometheus-stack  metrics and dashboards                  (planned)
```

- **Provisioning:** Terraform (`bpg/proxmox`), state in HCP Terraform, local execution.
- **Node OS:** Talos Linux — immutable, API-driven, no SSH. Why: [ADR 0001](docs/adr/0001-talos-instead-of-k3s.md).
- **Secrets:** SOPS + age. Only encrypted values are committed.
- **Delivery:** GitOps for the Kubernetes layer (Argo CD pulls and reconciles).
  The layers below it are push-based infrastructure as code.

## Status

| Step | State |
|---|---|
| Least-privilege Proxmox API token for Terraform | ✅ [runbook](docs/runbooks/proxmox-terraform-token.md) |
| Talos image (Image Factory schematic) + VM via Terraform | ✅ |
| Talos secrets (encrypted) + machine config patches | ✅ |
| Cluster bootstrap | ⏳ #4 |
| Argo CD + platform services | planned |
| Portfolio migration and v1 cutover | planned |
| Disaster-recovery drill: rebuild from zero, timed and documented | planned |

Known gaps are tracked as issues labelled [`type/debt`](../../issues?q=is%3Aissue+label%3Atype%2Fdebt).

## Layout

| Path | Contents | Applied by |
|---|---|---|
| `infra/` | Proxmox resources (Terraform) | me: `terraform apply` |
| `talos/` | Talos image schematic, encrypted secrets, config patches | me: `talosctl apply-config` |
| `ansible/` | Proxmox host baseline | me: `ansible-playbook` |
| `kubernetes/bootstrap/` | Argo CD + root application | me, once |
| `kubernetes/platform/` | Traefik, cloudflared, monitoring | Argo CD |
| `kubernetes/apps/` | Workloads | Argo CD |
| `docs/adr/` | Architecture decisions and why | — |
| `docs/runbooks/` | Rebuild and recovery procedures | — |

Folders appear when they get real content; empty placeholders are not committed.

## How changes are made

Issue → branch → pull request → rebase merge. `main` is protected: no direct
pushes, no force pushes, linear history. Every pull request carries its
verification evidence (plan output, `talosctl`/`kubectl` checks) and a rollback
note. Details for humans and AI agents: [AGENTS.md](AGENTS.md).

## Security model

- No plaintext secrets in git. SOPS rules live in `.sops.yaml`; GitHub secret
  scanning with push protection is enabled as a second net.
- Terraform reaches Proxmox through a dedicated `terraform@pve` token with a
  minimal role, never as root.
- Nodes hold no hand-placed credentials and have no SSH: Talos is managed only
  through its API.
- Generated configs containing plaintext secrets (`talosconfig`, Talos machine
  configs, kubeconfig) are build artifacts kept outside the repository.

## Tooling

CLI versions are pinned in `mise.toml`. On a fresh machine: `mise install`.
Work happens from WSL (Ubuntu) on Windows; see [AGENTS.md](AGENTS.md#environment).
