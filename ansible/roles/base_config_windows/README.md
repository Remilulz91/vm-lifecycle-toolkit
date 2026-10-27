# Role: `base_config_windows`

Baseline post-clone configuration for Windows VMs built by the Packer side (Windows 10 / 11, Server 2019 / 2022). The Packer templates ship with OpenSSH Server pre-installed, so Ansible connects over SSH (not WinRM) with PowerShell as the remote shell.

## What it does

1. **Rename** the computer (`win_hostname`). Reboots if the rename triggered a `reboot_required` (gated by `base_config_windows_reboot_after_rename`).
2. Sets the **timezone** (`win_timezone` — Windows TZ id, not IANA).
3. Creates a local **admin user**, member of the `Administrators` group.
4. Deploys the admin SSH public key to **`C:\ProgramData\ssh\administrators_authorized_keys`** — the special shared file Windows OpenSSH uses for ALL members of the Administrators group (a per-user `~/.ssh/authorized_keys` is **ignored** for admin accounts). ACL is locked down to `SYSTEM` + `BUILTIN\Administrators` only.
5. Hardens `sshd_config`: `PasswordAuthentication no`, `PubkeyAuthentication yes` (gated by `base_config_windows_harden_ssh`).
6. Ensures the `OpenSSH-Server-In-TCP` firewall rule is enabled on port 22.

## Required variables

| Variable | Where | Why |
|---|---|---|
| `base_config_windows_admin_ssh_public_key` | `group_vars/all.yml` (or `ADMIN_SSH_PUBLIC_KEY` env var — shared with the Linux role) | Public key authorized for the admin user. The role fails fast if empty — without a key, the VM is unreachable after SSH hardening. |

## Main defaults

| Variable | Default |
|---|---|
| `base_config_windows_hostname` | `{{ inventory_hostname }}` |
| `base_config_windows_timezone` | `Romance Standard Time` (Paris) |
| `base_config_windows_admin_user` | `admin` |
| `base_config_windows_reboot_after_rename` | `true` |
| `base_config_windows_reboot_timeout` | `600` |
| `base_config_windows_harden_ssh` | `true` |

To list all valid Windows TZ ids on any Windows box: `tzutil /l`.

## Inventory connection pattern

Windows hosts must set the right shell/connection vars. Put them under a dedicated group (`windows_clones` by convention), separate from the Linux `proxmox_clones` group:

```yaml
all:
  children:
    windows_clones:
      hosts:
        windows-example-01:
          source_template_vmid: 1101
          target_vmid: 2101
          target_name: "windows-example-01"
          target_ip: "192.168.1.230"
      vars:
        ansible_connection: ssh
        ansible_shell_type: powershell
        ansible_user: packer           # the admin user Packer created in the template
```

## Supported targets

- Windows 10 / 11 (desktop)
- Windows Server 2019 / 2022

With OpenSSH Server pre-installed by the Packer templates (see `hypervisors/{proxmox,esxi}/windows/`).
