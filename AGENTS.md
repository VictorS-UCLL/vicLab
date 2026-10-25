# AGENTS.md

Working agreement for anyone changing this repository — AI coding agents and
humans alike. Read this before proposing or running anything.

The owner must be able to explain every line of this repository in a technical
interview. Code or config that cannot be explained line by line is a liability,
not progress.

---

## 1. Hard rules

1. **Never commit a plaintext secret.** Tokens, keys, certificates, passwords,
   generated Talos configs, `talosconfig`, kubeconfig, Terraform state and plan
   files stay out of git. Secrets go into `*.sops.yaml` files and are encrypted
   before the first `git add`.
2. **Never push to `main`.** All changes go through a pull request. Do not try to
   bypass, weaken or edit the `protect-main` ruleset.
3. **Never apply without a reviewed plan.** No `terraform apply -auto-approve`,
   no `talosctl apply-config` or `kubectl apply` that the owner has not seen first.
4. **Verify, do not assume.** Check effective state with commands
   (`terraform plan`, `talosctl get ...`, `kubectl get ...`), not by reading
   files. Say explicitly when something is inferred rather than verified.
5. **Ask before anything destructive or irreversible:** destroying or replacing
   resources, deleting VMs, regenerating secrets, rotating tokens, changing
   repository settings, making packages public, force operations.
6. **Stay in scope.** Do the task that was asked. Anything else you notice
   becomes an issue, not an unrequested change.
7. **Prefer the simplest thing that works** and is explainable. Do not add
   tools, layers or abstractions without a stated reason.
8. **If it is not in git, it does not exist.** Any manual change made in an
   emergency is committed the same day or reverted.

---

## 2. Environment

| What | Where |
|---|---|
| Working copy | `C:\Users\HomePC\Documents\VicLab\vicLab`, used from WSL as `/mnt/c/Users/HomePC/Documents/VicLab/vicLab` |
| Shell | WSL **Ubuntu-26.04** (default distro). Never use the `docker-desktop` distro. |
| Git | **Only from WSL.** Mixing Windows git and WSL git on one checkout causes line-ending and file-mode noise. |
| Toolchain | Pinned in `mise.toml`; `mise install` |
| age private key | `~/.config/sops/age/keys.txt` in WSL (backed up in the password manager and offline). Never inside the repo. |
| HCP Terraform credentials | `~/.terraform.d/credentials.tfrc.json` (from `terraform login`) |
| Proxmox API token | Password manager only; exported per shell as `PROXMOX_VE_API_TOKEN` |
| Talos client config | `~/.talos/config` (talosctl default) |
| Generated Talos machine configs | `~/.vicLab/talos/` — outside the repo, contains plaintext secrets |
| kubeconfig | `~/.kube/config` |

WSL gotchas:
- `/etc/wsl.conf` mounts Windows drives with `metadata`; without it git fails
  with `chmod ... Operation not permitted`.
- The repo has `core.filemode false` and `.gitattributes` forces LF line endings.
- In interactive bash, `!` inside double quotes triggers history expansion.
  Use single quotes for strings like `terraform@pve!vicLab`.

---

## 3. Layout and sources of truth

See the layout table in `README.md`. Values that must stay consistent:

| Value | Source of truth | Must match |
|---|---|---|
| Talos version | `infra/variables.tf` (`talos_version`) | `talosctl` in `mise.toml`; installer tag in `talos/patches/common.yaml` |
| Image schematic | `talos/image/schematic.yaml` | `talos_schematic_id` in `infra/variables.tf`; installer image in `talos/patches/common.yaml` |
| Provider versions | `infra/versions.tf` + `infra/.terraform.lock.hcl` | — |
| VM sizing, MAC, VM ID | `infra/variables.tf`, `infra/talos.tf` | — |
| age recipient | `.sops.yaml` | the public key of the age key above |

Changing one side of a "must match" pair without the other is a bug.

---

## 4. Change workflow

### Issues
- One issue per unit of work or per known piece of debt. Not one per file or step.
- Labels: `type/feature`, `type/debt`, `type/docs`; `area/infra`, `area/talos`, `area/k8s`.
- Debt found while doing something else gets its own issue (`type/debt`), not a drive-by fix.

### Branches
- Always branch from an up-to-date `main`: `git switch main && git pull && git switch -c <branch>`.
- Naming: `feat/<topic>`, `fix/<topic>`, `docs/<topic>`, `chore/<topic>`.

### Commits
- Conventional Commits: `type(scope): summary`.
  Types used here: `feat`, `fix`, `docs`, `chore`, `build`, `refactor`.
  Scope is the area: `infra`, `talos`, `k8s`, `sops`, `github`, `adr`.
- **One concern per commit.** Installing something and configuring it are separate commits.
- Stage files explicitly (`git add <path>`); no blind `git add .`.
  Run `git status` before and `git diff --cached` before every commit.

### Pull requests
- Use the template (`.github/pull_request_template.md`): what and why, linked
  issue (`Closes #N`), verification evidence, rollback.
- Verification means real command output: the reviewed `terraform plan`,
  `talosctl` / `kubectl` results. "It works" is not evidence.
- Open the PR when the change is verified, not before.
- Merge method: **Rebase and merge** only (linear history, per-concern commits
  preserved). Head branches are deleted automatically.

### Repository protection (`protect-main` ruleset)
Pull request required (0 approvals — single maintainer), linear history, no
force pushes, no deletion, empty bypass list. Secret scanning and push
protection are on. Actions default to read-only `GITHUB_TOKEN` permissions;
workflows request more explicitly.

---

## 5. Terraform (`infra/`)

```bash
cd infra
read -rsp "Proxmox token secret: " PVE_SECRET; echo
export PROXMOX_VE_API_TOKEN='terraform@pve!vicLab='"$PVE_SECRET"
unset PVE_SECRET

terraform init
terraform fmt -check
terraform validate
terraform plan -out=apply.tfplan   # owner reviews this output
terraform apply apply.tfplan       # applies exactly the reviewed plan
rm apply.tfplan
```

- State lives in HCP Terraform (org `vicLab`, workspace `proxmox`, execution
  mode **Local**). Never use a local state file.
- Read drift without changing anything: `terraform apply -refresh-only`.
- Fix deprecation warnings when they appear; do not build on deprecated resources.
- Provider versions are pinned to patch level for 0.x providers (`~> 0.118.0`).
- `reboot_after_update = true` on the VM: changes such as memory reboot the only
  node, i.e. the whole cluster. Call this out in the PR.
- The Proxmox token, user and role are documented in
  `docs/runbooks/proxmox-terraform-token.md`. New privileges are added only when
  a real permission error proves they are needed (PVE 9 has no `VM.Monitor`).
- The Proxmox UI is read-only for Terraform-managed resources.

---

## 6. Talos (`talos/`)

- `talos/secrets.sops.yaml` — cluster identity (CAs, tokens). Fully encrypted.
  Regenerating it means a new cluster: ask first.
- `talos/patches/` — the only hand-written machine config. Everything else is generated.
- The install image **must** be the Image Factory installer for our schematic
  (`factory.talos.dev/installer/<schematic-id>:<version>`). The default installer
  drops system extensions such as `qemu-guest-agent`.
- Generated machine configs are build artifacts: write them to `~/.vicLab/talos/`,
  never into the repository.
- `--insecure` is only valid against a node in maintenance mode (first apply).
- Upgrades: `talosctl upgrade --image <installer>:<new-version>`, after bumping
  every value listed in section 3.

---

## 7. Secrets (SOPS + age)

Rules in `.sops.yaml`:
- `talos/**/*.sops.yaml`: every value encrypted.
- `kubernetes/**/*.sops.yaml`: only `data` / `stringData` encrypted, so `kind`
  and `metadata` stay readable for diffs and Argo CD.

```bash
sops -e -i <path>.sops.yaml          # encrypt in place, before git add
sops edit <path>.sops.yaml           # edit; never decrypt to a file in the repo
sops -d <path>.sops.yaml > /dev/null && echo "decrypt OK"
sed '/^sops:/,$d' <path>.sops.yaml | grep -v 'ENC\['   # must print only bare keys
```

Run the last two checks before committing any secrets file.

---

## 8. Kubernetes and GitOps (`kubernetes/`) — applies once Argo CD runs

- Git is the only way to change cluster state for Argo CD-managed resources.
  No `kubectl apply`/`edit`/`patch` on them; Argo CD self-heal reverts drift.
- Images are pinned by immutable tag or digest with `imagePullPolicy: IfNotPresent`.
  (v1 lesson: `Always` with immutable tags turned a registry hiccup into an outage.)
- Every container: resource requests/limits, non-root, read-only root filesystem
  where possible, all capabilities dropped, `RuntimeDefault` seccomp.
- Secrets are `*.sops.yaml` files under `kubernetes/`; never `kubectl create secret` by hand.
- Public images need no pull credentials; do not place registry credentials on nodes.

---

## 9. Documentation

- **ADR** (`docs/adr/NNNN-title.md`) for every decision someone could reasonably
  ask "why?" about. Written at the moment the decision is implemented, in the
  owner's words: context, decision, consequences (good and bad), rejected alternatives.
- **Runbooks** (`docs/runbooks/`) for any procedure run by hand.
- Update the Status table in `README.md` in the same PR that changes the status.

---

## 10. Facts and gotchas

- Proxmox node `pve` at `192.168.0.50`, PVE 9.x. Self-signed certificate (#1).
- IPv6 does not route on the LAN (#2). The kubelet is pinned to `192.168.0.0/24`.
- The Talos node's static IP must be outside the router's DHCP pool.
- Proxmox noVNC console cannot paste; VMs get a serial console (xterm.js supports paste).
- `bpg/proxmox`: `cdrom.enabled` is deprecated and ignored; `proxmox_download_file`
  replaces `proxmox_virtual_environment_download_file`.
- Talos `--insecure` is required only in maintenance mode; after install, use `~/.talos/config`.

---

## 11. Legacy (v1)

- v1 lives in `homelab-k3s`, `vic-dashboard`, `homelab-ansible`, `homelab-etc-config`.
- Proxmox VMs 100 (`k3s-main`, serving vic420.com as a stopgap), 101 and template
  9000 are v1. Do not change them except to retire them at cutover.
