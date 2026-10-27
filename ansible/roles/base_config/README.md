# Role: `base_config`

Baseline post-clone configuration for every VM in the inventory.

Applied over SSH **after** the VM has been cloned, started, and is reachable (`target_ip` set on the host, SSH on port 22 responding).

## What it does

1. Sets the system hostname (defaults to `inventory_hostname`, which is `target_name` for VMs produced by the clone role).
2. Sets the timezone (defaults to `Europe/Paris`).
3. Installs a small set of base packages (`sudo`, `curl`, `vim`, `htop`, `net-tools`, `rsync`, `ca-certificates`, `gnupg`, …).
4. Creates a single admin user (default name: `admin`) with:
   - Membership in the `sudo` group
   - Your SSH public key authorized
   - Passwordless sudo via `/etc/sudoers.d/90-admin`
5. Hardens sshd: `PasswordAuthentication no`, `PermitRootLogin no`, `KbdInteractiveAuthentication no` (gated by `base_config_harden_ssh`).
6. Optionally runs a full `apt upgrade` (gated by `base_config_apt_upgrade`, default `false`).

## Required variables

| Variable | Where | Why |
|---|---|---|
| `base_config_admin_ssh_public_key` | `group_vars/all.yml` | Public key authorized for the admin user. The role **fails fast** if missing — without a key, SSH hardening would lock the VM. |

## Main defaults (overridable)

| Variable | Default |
|---|---|
| `base_config_hostname` | `{{ inventory_hostname }}` |
| `base_config_timezone` | `Europe/Paris` |
| `base_config_admin_user` | `admin` |
| `base_config_packages` | `[sudo, curl, wget, vim, htop, net-tools, ca-certificates, rsync, gnupg]` |
| `base_config_harden_ssh` | `true` |
| `base_config_apt_update_cache` | `true` |
| `base_config_apt_upgrade` | `false` |

## Supported targets

- Debian 12 / 13
- Ubuntu 22.04 / 24.04 / 26.04 Server

Windows targets are not supported in this role (planned for a separate `base_config_windows` role in a later version).
