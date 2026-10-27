# Role: `esxi_decommission`

Destructively tears down a VM on a standalone ESXi host: forced power-off then full delete (disks + VMX + folder). Mirror of `esxi_deploy`.

**This role is destructive.** Only invoked by `playbooks/decommission-vm.yml`, which refuses to run without an explicit `confirm_decommission=yes` extra-var.

## What it does

1. Validates `target_name`.
2. Looks up the VM via `vmware_vm_info`. If it's already gone, the role **ends the host cleanly** (`meta: end_host`) rather than failing — makes the playbook idempotent for already-decommissioned entries.
3. Forced power-off via `vmware_guest_powerstate`.
4. Deletes via `vmware_guest` with `state: absent, force: true` — removes disks and all VM files.

Credentials come from the same `inventories/esxi/group_vars/all.yml` as `esxi_deploy` (`ESXI_HOSTNAME`, `ESXI_PASSWORD`).
