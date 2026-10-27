# V3.7.6 — Dynamic inventory for Proxmox + ESXi

Operate on live VMs without editing `hosts.yml`. Both hypervisors now expose a dynamic inventory source that queries their API directly and feeds the hostlist to Ansible.

## What's new

### Dynamic inventory sources

- **`inventories/proxmox/proxmox.yml`** — uses the `community.proxmox.proxmox` plugin. Queries `/api2/json/cluster/resources`, pulls VM status, QEMU-agent interfaces, tags.
- **`inventories/esxi/esxi.yml`** — uses the `community.vmware.vmware_vm_inventory` plugin via pyvmomi. Pulls name, power state, guest IP, guest OS family, CPU/memory.

Both files live **next to** the existing `hosts.yml`. Ansible merges every inventory source in a directory, so `-i inventories/proxmox/` gives you the union: planned clones from the static file **plus** every live VM returned by the plugin.

### Automatic groupings (at query time)

**Proxmox**
- Every Proxmox tag becomes an Ansible group. Tag a VM `docker_hosts` in Proxmox → it feeds into the Docker specialization play automatically, no inventory edit.
- `proxmox_running` / `proxmox_stopped` from VM status.
- `node_<nodename>` per hypervisor node.

**ESXi**
- `esxi_power_poweredOn` / `esxi_power_poweredOff` from runtime state.
- `esxi_guest_os_*` from the configured guest-OS family.

### `ansible_host` auto-filled

- Proxmox: first non-loopback, non-link-local IP from `proxmox_agent_interfaces` (QEMU-guest-agent must be running on the VM — already the case for Packer-built templates).
- ESXi: `guest.ipAddress` reported by VMware Tools.
- Fallback for both: the VM name (useful if the agent/tools haven't reported yet).

### Inventory cache

`ansible.cfg` now enables the JSONFile cache plugin:

```ini
[inventory]
enable_plugins = community.proxmox.proxmox, community.vmware.vmware_vm_inventory, auto, yaml, ini, host_list, script, toml
cache = True
cache_plugin = jsonfile
cache_connection = ./.inventory-cache
cache_timeout = 300
```

5-minute TTL. Clear manually with `rm -rf .inventory-cache/` to force a fresh fetch. The cache directory is `.gitignore`'d.

### Credentials

Unchanged — the dynamic plugins reuse the same env vars as the clone/deploy flow:
- Proxmox: `PROXMOX_API_HOST` + `PROXMOX_API_TOKEN_SECRET`
- ESXi: `ESXI_HOSTNAME` + `ESXI_PASSWORD`

## Typical use cases

```bash
# See what's live right now
ansible-inventory -i inventories/proxmox/ --graph
ansible-inventory -i inventories/esxi/    --graph

# Ad-hoc ping across every running Proxmox VM
ansible -i inventories/proxmox/ proxmox_running -m ansible.builtin.ping

# Re-apply base_config to a single existing VM — no hosts.yml edit needed
ansible-playbook -i inventories/proxmox/ playbooks/configure-vm.yml \
    --limit some-existing-vm

# Install Docker on every VM tagged `docker_hosts` in Proxmox
ansible-playbook -i inventories/proxmox/ playbooks/configure-vm.yml \
    --limit docker_hosts
```

## Not included (planned)

- V3.7.7 — Decommission playbook (clean VM teardown — Proxmox + ESXi)
- V3.8   — Terraform side (clone + offline support)
