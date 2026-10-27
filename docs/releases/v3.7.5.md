# V3.7.5 — Standalone ESXi deploy via OVF

Brings the Ansible side to **full hypervisor parity**: both Proxmox and standalone ESXi are now covered, from clone/deploy to configuration. The configure playbook is hypervisor-agnostic — the same `base_config` and `base_config_windows` roles run regardless of where the VM lives.

## Architecture note

Standalone ESXi has no `MarkAsTemplate` API (it's a vCenter-only feature). The flow is therefore:

```
Packer-built VM on ESXi    ovftool (manual, once per template)    esxi_deploy (Ansible)
───────────────────────    ────────────────────────────────────    ─────────────────────
"debian-13-template"   →   ansible/ovf-sources/debian-13/*.ovf  →  One VM per inventory entry
```

The `ovftool` export is done once per template on the controller; `esxi_deploy` then redeploys that OVF for every clone.

## What's new

### Role `esxi_deploy`

- Uses `community.vmware.vmware_deploy_ovf` — works on standalone ESXi hosts (no vCenter needed).
- Validates OVF presence on the controller with a fail-fast + a ready-to-run `ovftool` command in the error message.
- Applies optional CPU/RAM overrides via `community.vmware.vmware_guest` after deploy.
- Powers on the VM and optionally waits for SSH on `target_ip`.
- Configurable disk provisioning (`thin` / `thick`), timeouts, and OVF network label.

### Playbook `deploy-from-ovf.yml`

Parallel to `clone-from-template.yml`. Targets `esxi_clones:esxi_windows_clones` (the OVF deploy itself is OS-agnostic — the OVF carries the OS).

### Inventory `inventories/esxi/`

Mirrors the Proxmox layout:

- `hosts.yml` with groups `esxi_clones` (Linux), `esxi_windows_clones`, plus the shared specialization groups `docker_hosts` / `webservers`.
- `group_vars/all.yml` — ESXi endpoint (`ESXI_HOSTNAME`), credentials (`ESXI_USERNAME`, `ESXI_PASSWORD`), datastore, network, OVF network label. SSH connection vars for the deployed Linux VMs.
- `group_vars/esxi_windows_clones.yml` — Windows SSH + PowerShell connection vars (same env vars as the Proxmox-side Windows: `PACKER_WINDOWS_SSH_USER`, `ADMIN_SSH_PUBLIC_KEY`).

### `configure-vm.yml` extended

- Baseline Linux play now targets `proxmox_clones:esxi_clones`.
- Baseline Windows play now targets `windows_clones:esxi_windows_clones`.
- Specialization plays (`docker_hosts`, `webservers`) are unchanged — they already work across hypervisors because the groups are shared.

### Dependencies

- Added **`community.vmware ≥ 4.0.0`** to `requirements.yml`.
- Added **`pyvmomi ≥ 8.0.0`** to `requirements.txt`.
- Re-run `scripts/prepare-offline-bundle.sh` on the online host if you use the air-gapped flow, so the new collection + wheel are packaged into the next bundle.

### `.gitignore`

- Adds `ansible/ovf-sources/` so OVF/VMDK binaries never land in git.

## Typical workflow (ESXi, end to end)

```bash
# ---------- One-off: export the Packer-built template to OVF ----------
# (install VMware ovftool once on the controller)
ovftool \
  vi://root@esxi01.lan/debian-13-template \
  ansible/ovf-sources/debian-13/debian-13.ovf

# ---------- Step 1: deploy from OVF ----------
export ESXI_HOSTNAME=esxi01.lan
export ESXI_PASSWORD=xxxxxxxx
# optional: ESXI_USERNAME (default root), ESXI_DATASTORE (default datastore1),
#           ESXI_NETWORK (default "VM Network")

cd ansible/
ansible-playbook -i inventories/esxi/ playbooks/deploy-from-ovf.yml

# ---------- Step 2: baseline + specialization (same roles as Proxmox) ----------
export ADMIN_SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"
ansible-playbook -i inventories/esxi/ playbooks/configure-vm.yml

# From now on: ssh admin@<target_ip>
```

## Not included (planned)

- V3.7.6 — Dynamic inventory (query Proxmox / ESXi for existing VMs)
- V3.7.7 — Decommission playbook (clean VM teardown — Proxmox + ESXi)
- V3.8   — Terraform side (clone + offline support)
