# V3.7.7 — Decommission playbook (lifecycle loop closed)

Last brick of the V3.7.x Ansible track: a confirm-gated, hypervisor-aware teardown playbook that permanently removes VMs. The toolkit now covers the full cycle — clone/deploy → configure → **decommission** — on both Proxmox and standalone ESXi.

## What's new

### Playbook `decommission-vm.yml`

- **Mandatory safety gate** — the first play runs on `localhost` and asserts the extra-var `confirm_decommission=yes`. Any other value, or omission, aborts before any destructive API call fires.
- **`serial: 1`** throughout — one VM at a time. A scoping mistake stops after exactly one teardown instead of parallelising the damage across the whole inventory.
- **Covers both hypervisors** in a single run — Proxmox (`proxmox_clones:windows_clones`) and ESXi (`esxi_clones:esxi_windows_clones`). The right inventory source and roles pick up each side.

### Role `proxmox_decommission`

- Looks up the VM with `community.proxmox.proxmox_vm_info`.
- A missing VM is **not an error** — the role ends the host cleanly via `meta: end_host`, so a replay after a partial run is idempotent.
- Forced stop (`community.proxmox.proxmox_kvm` with `state: stopped, force: true`).
- Full delete (`state: absent`) — removes disks and config atomically.

### Role `esxi_decommission`

- Looks up the VM with `community.vmware.vmware_vm_info`.
- Missing VM = clean skip, same pattern as the Proxmox role.
- Forced power-off via `vmware_guest_powerstate`.
- Full delete via `vmware_guest` with `state: absent, force: true` (removes disks, VMX, and the VM folder on the datastore).

## Typical usage

```bash
# Decommission ONE Proxmox VM (safest form — explicit --limit + confirm)
ansible-playbook -i inventories/proxmox/ playbooks/decommission-vm.yml \
    --limit debian-example-01 \
    -e confirm_decommission=yes

# Decommission ONE ESXi VM
ansible-playbook -i inventories/esxi/ playbooks/decommission-vm.yml \
    --limit debian-esxi-01 \
    -e confirm_decommission=yes

# Decommission every VM in the Proxmox inventory
# (still serial, still gated, but obviously wider — use with care)
ansible-playbook -i inventories/proxmox/ playbooks/decommission-vm.yml \
    -e confirm_decommission=yes
```

Without `-e confirm_decommission=yes` the playbook refuses to run, printing the exact fix in its error message.

## V3.7.x lifecycle track — complete

```
Clone/Deploy      Configure              Decommission
──────────────    ──────────────────     ──────────────────
proxmox_clone  →  base_config         →  proxmox_decommission
esxi_deploy       base_config_windows    esxi_decommission
                  docker_host
                  webserver
```

Everything the Ansible side needs for day-to-day VM operations on this toolkit is now in place. V3.8 (Terraform) picks up next, when the user asks for it.
