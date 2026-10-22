# 🧬 proxmox_clone — Ansible role

Clones a VM from a Packer-built Proxmox template, optionally overrides hardware specs, starts the clone, and (optionally) waits for SSH.

## Inputs

### Required (per inventory host)

| Variable               | Description                                                       |
| ---------------------- | ----------------------------------------------------------------- |
| `source_template_vmid` | VMID of the Packer-built template to clone from                   |
| `target_vmid`          | VMID for the new clone — must be unique and ≥ 1000                |
| `target_name`          | Name shown in the Proxmox UI (also the Linux hostname by default) |

### Optional (per inventory host)

| Variable           | Description                                                                |
| ------------------ | -------------------------------------------------------------------------- |
| `target_cores`     | Override CPU core count. If omitted, inherits from template.               |
| `target_memory_mb` | Override RAM in MiB. If omitted, inherits from template.                   |
| `target_ip`        | If set, Ansible waits for SSH on port 22 of this IP after starting the VM. |

### Shared / infrastructure (from `group_vars/all.yml`)

- `proxmox_api_host`, `proxmox_api_user`, `proxmox_api_token_id`, `proxmox_api_token_secret`
- `proxmox_node`
- `clone_mode` (`full` or `linked`)
- `clone_timeout_seconds`, `ssh_wait_timeout_seconds`

## Example inventory entry

```yaml
all:
  children:
    proxmox_clones:
      hosts:
        my-webserver:
          source_template_vmid: 1001
          target_vmid: 2010
          target_name: "my-webserver"
          target_cores: 4
          target_memory_mb: 8192
          target_ip: "192.168.1.210"
```

## What the role does

1. Validates required inventory variables.
2. Clones the VM from the source template (uses `clone_mode` to pick full vs linked).
3. Applies hardware overrides (if `target_cores` or `target_memory_mb` are set).
4. Starts the cloned VM.
5. Waits for SSH on port 22 of `target_ip` (if set).
6. Prints a success message.

Nothing is modified inside the guest OS — that's for post-clone configuration roles (planned in a later iteration).
