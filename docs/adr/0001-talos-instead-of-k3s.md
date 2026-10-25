# ADR 0001: Talos Linux instead of K3s on Ubuntu

- Status: accepted
- Date: 2026-10-25

## Context

v1 ran K3s on a hand-configured Ubuntu VM. Important state lived only on the
node and in nobody's git: the portfolio hardening (one unpushed commit), the
cloudflared config, a Docker install and cron job left over from old CI, and
sudoers files the README described but that did not exist. Recovering v1 after
losing my workstation meant doing forensics on the VM.

My UCLL Cloud & Ops course also uses Talos.

## Decision

Run Kubernetes on Talos Linux: one node, as a Proxmox VM created by Terraform.

## Consequences

Good:
- The node is fully described by a machine config generated from git
  (SOPS-encrypted secrets plus patches). No SSH, no shell, nothing to drift.
- Upstream Kubernetes components and etcd: closer to what the CKA tests than
  K3s's single binary with SQLite.
- Immutable OS; upgrades are an API call (`talosctl upgrade`), not apt.

Bad:
- No shell to debug with: everything goes through talosctl and kubectl.
- One node means no high availability. Control plane and workloads share one VM
  on one laptop.
- Talos-specific traps: extensions must be in the installer image, not only the
  boot ISO; local storage needs explicit configuration.

## Rejected alternatives

- K3s on Ubuntu again: it works, but the node stays a hand-maintained pet.
- Three Talos nodes on one laptop: looks like HA, but they would share one disk,
  one power supply and one network card. Not real redundancy.
