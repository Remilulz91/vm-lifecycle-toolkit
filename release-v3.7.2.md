# V3.7.2 — Baseline post-clone configuration

Step 2 of the Ansible lifecycle: configure the VM once it's been cloned and started.

## What's new

- **New role `base_config`** — baseline post-clone configuration applied over SSH on Debian/Ubuntu VMs:
  - Hostname (defaults to the inventory host name = `target_name`)
  - Timezone (default `Europe/Paris`, overridable)
  - Base package set: `sudo`, `curl`, `wget`, `vim`, `htop`, `net-tools`, `ca-certificates`, `rsync`, `gnupg`
  - A single `admin` user: added to `sudo`, authorized SSH key, passwordless sudo via `/etc/sudoers.d/90-admin`
  - SSH hardening: `PasswordAuthentication no`, `PermitRootLogin no`, `KbdInteractiveAuthentication no` (with `sshd -t` validation + handler restart)
  - Optional full `apt upgrade` behind `base_config_apt_upgrade` flag (default `false`)
- **New playbook `playbooks/configure-vm.yml`** — step 2 of the lifecycle. Connects to each VM over SSH as the Packer-created user, applies `base_config`. Pre-task asserts `target_ip` is set on the host.
- **Fail-fast on missing admin key** — the role refuses to run if `base_config_admin_ssh_public_key` is empty. Prevents SSH-hardening a VM into a brick.
- **`group_vars/all.yml` extended** with:
  - SSH connection vars: `ansible_host`, `ansible_user`, `ansible_ssh_private_key_file`, `ansible_ssh_common_args`
  - `base_config_admin_user` / `base_config_admin_ssh_public_key` / `base_config_timezone`
  - Public key passed via `ADMIN_SSH_PUBLIC_KEY` env var

## Typical workflow

```bash
# ---------- Step 1: clone + start (Proxmox API) ----------
export PROXMOX_API_HOST=10.0.0.10
export PROXMOX_NODE=pve01
export PROXMOX_API_TOKEN_SECRET=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
cd ansible/
ansible-playbook playbooks/clone-from-template.yml

# ---------- Step 2: baseline config (SSH) ----------
export ADMIN_SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"
ansible-playbook playbooks/configure-vm.yml

# From now on, SSH as the new admin:
ssh admin@<target_ip>
```

## Scope boundaries

- **Linux only** — Debian 12/13, Ubuntu 22.04/24.04/26.04 Server. Windows `base_config_windows` planned for V3.7.3.
- **One admin user, shared across all VMs** — per-host override is possible via inventory, but the default pattern is a single team key for simplicity.
- **No specialized roles yet** — `docker_host`, `webserver`, etc. planned for V3.7.3.
- **No automatic chaining** — step 2 is a separate playbook on purpose, so you can re-configure a VM without recloning it.

## Not included (planned)

- V3.7.3 — Specialized roles (`docker_host`, `webserver`) + Windows baseline
- V3.7.4 — ESXi Ansible support
- V3.7.5 — Dynamic inventory (query Proxmox for existing VMs)
- V3.7.6 — Decommission playbook
- V3.8   — Terraform side (clone + offline support)
