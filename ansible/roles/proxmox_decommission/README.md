# Role: `proxmox_decommission`

Destructively tears down a VM on Proxmox: forced stop if running, then full delete (disks + config). Mirror of `proxmox_clone`.

**This role is destructive.** It is only invoked by `playbooks/decommission-vm.yml`, which refuses to run without an explicit `confirm_decommission=yes` extra-var. Never run this role alone from an ad-hoc play without that gate.

## What it does

1. Validates `target_vmid` and `target_name`.
2. Looks up the VM via `proxmox_vm_info`. If the VM is already gone, the role **ends the host cleanly** (`meta: end_host`) rather than failing — makes the playbook idempotent for already-decommissioned entries.
3. Forced stop (`state: stopped, force: true`) — gracefully if possible, otherwise cut power.
4. Full delete (`state: absent`) — removes disks and the VM config atomically.

Credentials and node come from the same group_vars as `proxmox_clone` (`PROXMOX_API_HOST`, `PROXMOX_API_TOKEN_SECRET`, `PROXMOX_NODE`).
